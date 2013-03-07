program fmo_prop

  use qdyn
  use fmo_globals_mod
  use fmo_open_close_mod
  implicit none

  ! Local Variables
  integer :: error
  integer :: i

  ! Note: variables shared between propagation and OCT are defined globally in
  ! the fmo_globals_mod module

  character (len=error_l) :: module_name = 'fmo_prop'

  !! @description: Propagate the system (for analysis)

  call getarg(1, rf) ! name of runfolder must be passed as command line argument
  call read_para(para, rf, configfile='config')
  call debug_para_t(para, 'para', expand=1)

  write (*,*) "Starting on "//trim(date_string())
  call print_version_info('fmo_prop')

  call init(para, grid=grid, pulses=pulses)
  call init_ham(ham_x, grid, pulses, para, system='ham_x')
  call load_dissipator(ham_x, join_path(rf, 'dissipator-real'), &
  &                           join_path(rf, 'dissipator-imag'))
  call init_ham(ham_y, grid, pulses, para, system='ham_y')
  call load_dissipator(ham_y, join_path(rf, 'dissipator-real'), &
  &                           join_path(rf, 'dissipator-imag'))
  call init_ham(ham_z, grid, pulses, para, system='ham_z')
  call load_dissipator(ham_z, join_path(rf, 'dissipator-real'), &
  &                           join_path(rf, 'dissipator-imag'))
  call init_psi(rho_in, grid, nsurf=8, spindim=1, para=para, system='rho_in')
  call init_psi(rho_tgt, grid, nsurf=8, spindim=1, para=para, system='rho_tgt')
  call psi_to_rho(rho_in)
  call psi_to_rho(rho_tgt)
  call debug_ham_t(ham_x, 'ham_x', filename=join_path(rf, 'ham.debug'), &
  &                expand=2)
  call debug_ham_t(ham_y, 'ham_y', filename=join_path(rf, 'ham.debug'), &
  &                expand=2, append=.true.)
  call debug_ham_t(ham_z, 'ham_z', filename=join_path(rf, 'ham.debug'), &
  &                expand=2, append=.true.)
  call debug_state_t(rho_in, 'rho_in', filename=join_path(rf, 'rho.debug'))
  call debug_state_t(rho_tgt, 'rho_tg', filename=join_path(rf, 'rho.debug'), &
  &                  append=.true.)
  call debug_pulse_t(pulses(1), 'pulse', filename=join_path(rf, 'pulse.debug'))

  write(*,'("*** Pulse Initialization ***")')
  write(*,'("Using pulse.dat (overriding config)")')
  if (allocated(pulses)) deallocate(pulses)
  allocate(pulses(1), stat=error)
  call allocerror(module_name, 'main', error)
  call read_pulse(pulses(1), join_path(rf, 'pulse.dat'), time_unit='fs')
  write (*,'("")')


  write(*,'("*** Preparing Propagation ***")')
  call set_oct_target(targets, 1, 3, rho_in, ham_x, grid, rho_tgt)
  call set_oct_target(targets, 2, 3, rho_in, ham_y, grid, rho_tgt)
  call set_oct_target(targets, 3, 3, rho_in, ham_z, grid, rho_tgt)
  do i = 1, 3
    write(*,*) "x(1), y(2), z(3) : ", i
    call init_prop(targets(i)%ham, targets(i)%grid, targets(i)%prop_work,    &
    &              para, pulses, rho=targets(i)%in_liouville_space)
  end do
  call dump_ascii_prop_work_t(targets(1)%prop_work, &
  & filename=join_path(rf, 'prop_work.debug'))
  call open_prop_files()
  write (*,'("")')

  write(*,'("*** Propagating ***")')

  rho = targets(1)%state_initial
  write(funit('pop.dat'),'(A)') ""
  write(funit('pop.dat'),'(A)') ""
  write(funit('pop.dat'),'(A)') "# x-direction"
  call prop(rho, targets(1)%grid, targets(1)%ham, targets(1)%prop_work,   &
  &         para, pulses, prop_info_hook=plot_rho_prop)

  write(funit('pop.dat'),'(A)') ""
  write(funit('pop.dat'),'(A)') ""
  write(funit('pop.dat'),'(A)') "# y-direction"
  rho = targets(2)%state_initial
  call prop(rho, targets(2)%grid, targets(2)%ham, targets(2)%prop_work,   &
  &         para, pulses, prop_info_hook=plot_rho_prop)

  write(funit('pop.dat'),'(A)') ""
  write(funit('pop.dat'),'(A)') ""
  write(funit('pop.dat'),'(A)') "# z-direction"
  rho = targets(3)%state_initial
  call prop(rho, targets(3)%grid, targets(3)%ham, targets(3)%prop_work,   &
  &         para, pulses, prop_info_hook=plot_rho_prop)

  write (*,'("")')
  ! TODO: calculate and print whatever is interesting about the final propagated
  ! state

  call close_prop_files()

  write (*,'("")')
  write (*,'(A)') "Done: "//trim(date_string())

end program fmo_prop
