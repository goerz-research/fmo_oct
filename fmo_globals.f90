module fmo_globals_mod

  use qdyn
  implicit none

  private :: module_name

  public
  integer :: pulse_nt

  character(len=error_l) :: module_name = 'fmo_globals_mod'

  character(len=file_l) :: rf ! name of runfolder
  type(grid_t) :: grid
  type(ham_t)  :: ham_x, ham_y, ham_z
  type(prop_work_t) :: work
  type(para_t), save :: para
  type(pulse_t), allocatable :: pulses(:)
  type(oct_target_t), allocatable :: targets(:)

  type(state_t) :: rho_in
  type(state_t) :: rho_tgt
  type(state_t) :: rho


contains


  !!@description: Print compilation/version information about fmo programs
  !!              and qdyn
  subroutine print_version_info(progname)

    character(len=*) :: progname
    include "VERSION.fi"
    write(*,'("")')
    write(*,'("This is ",A," rev.",A)') progname, trim(FMO_GITVERSION)
    write(*,*) "compiled on ", trim(FMO_COMPILE_TIME), &
    &          " on host ", trim(FMO_COMPILE_HOST)
    write(*,*) "Using qdyn ver. ", trim(QDYN_VERSION), &
    &          " revision " , trim(QDYN_GITVERSION), &
    &          " (", trim(QDYN_GITBRANCH), ")"
    write(*,*) "compiled on ", trim(QDYN_COMPILE_TIME), &
    &          " on host ", trim(QDYN_COMPILE_HOST)
    write(*,'("")')

  end subroutine print_version_info


  !! @description            Add the dissipator as an explicit matrix, stored in
  !!                         ham%dissipator_matrix
  !! @param: ham             Hamiltonian for which to load the dissipator
  !! @param: diss_file_real  Name of file containing the real part of the
  !!                         dissipator
  !! @param: diss_file_imag  Name of file containing the imag part of the
  !!                         dissipator
  subroutine load_dissipator(ham, diss_file_real, diss_file_imag)

    type(ham_t),      intent(inout) :: ham
    character(len=*), intent(in)    :: diss_file_real
    character(len=*), intent(in)    :: diss_file_imag

    integer :: error, n
    real(idp), allocatable :: dissipator_matrix_real(:,:)
    real(idp), allocatable :: dissipator_matrix_imag(:,:)

    character(len=error_l) :: routine_name = 'load_dissipator'
    call add_backtrace(module_name, routine_name)

    call read_ascii_table(dissipator_matrix_real, diss_file_real)
    call read_ascii_table(dissipator_matrix_imag, diss_file_imag)

    n = size(dissipator_matrix_real(:,1))
    allocate(ham%dissipator_matrix(n,n), stat=error)
    call allocerror(module_name, routine_name, error)

    ham%dissipator_matrix = dissipator_matrix_real + ci * dissipator_matrix_imag

    deallocate(dissipator_matrix_real, dissipator_matrix_imag)
    call del_backtrace()

  end subroutine load_dissipator


  ! ############################################################################
  ! Info-Hook routines: these are called automaticaly by prop or OCT
  !
  ! The routines can make use both of the variables passed to them (as
  ! documented), and global module variables in the fmo_globals_mod module. In
  ! fact, the primary reason for defining all the main variables globally in
  ! this module is to make them avaialable to the info-hook routines
  !
  ! ############################################################################


  !! @description: Propagation info_hook that just prints out the time (for
  !!               debugging). This routine is called after each propagation
  !!               step, including once for the initial state (with ti=0)
  !! @param: rho   State resulting from propagating up to time step ti
  !! @param: grid  Spatial grid
  !! @param: ham   Hamiltonian
  !! @param: ti    Time index, that is the time step we're at in the propagation
  !! @param: work  Data structure for internal work arrays used in propagation
  !! @param: param Config file parameters
  subroutine plot_rho_prop(rho, grid, ham, ti, work, para)

    type(state_t),     intent(in)    :: rho
    type(grid_t),      intent(in)    :: grid
    type(ham_t),       intent(in)    :: ham
    integer,           intent(in)    :: ti
    type(prop_work_t), intent(inout) :: work
    type(para_t),      intent(in)    :: para

    real(idp) :: t
    integer :: i, n
    integer :: cavity_pop_level
    character(len=11) :: row_format
    real(idp) :: p(8)

    t = para%tgrid%int(1)%t_start + ti*para%tgrid%int(1)%dt

    do i = 1, 8
      p(i) = real(rho%rho(1,1,i,1,1,i), idp)
    end do
    write(funit('pop.dat'), '(9ES15.6)') conv_from_au(t, 'fs'), p

  end subroutine plot_rho_prop


  !! @description: Write out information about tau and pulse fluence. This
  !! routine is called after each OCT iteration
  !! @param: iter         OCT iteration number
  !! @param: oct_info     Special data structure containing loads of information
  !!                      about optimization functionals etc
  !! @param: targets      Array of optimization targets (just one for
  !!                      state-to-state)
  !! @param: fw_states_T  Array of states, propagated forward the the optimized
  !!                      pulse from the current OCT iteration (again just one
  !!                      state for state-to-state OCT)
  !! @param: pulses0      Array of guess pulses
  !! @param: pulses1      Array of optimized pulses
  !! @param: para         Config file parameters
  subroutine write_oct_iteration(iter, oct_info, targets, fw_states_T,         &
  & pulses0, pulses1, para)

    use def_mod
    use global_mod
    integer,            intent(in)    :: iter
    type(oct_info_t),   intent(inout) :: oct_info
    type(oct_target_t), intent(in)    :: targets(:)
    type(state_t),      intent(in)    :: fw_states_T(:)
    type(pulse_t),      intent(in)    :: pulses0(:)
    type(pulse_t),      intent(in)    :: pulses1(:)
    type(para_t),       intent(in)    :: para

    real(idp) :: tau
    real(idp) :: phi

    tau = abs(oct_info%tau_s(1))
    phi = normal_phase(atan2( aimag(oct_info%tau_s(1)),               &
    &                         real(oct_info%tau_s(1), idp) )    ) / pi

    write(funit('tau.dat'),'(I10,2F15.9)') &
    & iter, tau, phi

    write(funit('fluence.dat'),'(I10,ES25.16)') &
    & iter, pulse_fluence(pulses1(1))

  end subroutine write_oct_iteration

end module fmo_globals_mod
