program fmo_oct

  use qdyn
  use fmo_globals_mod
  use fmo_open_close_mod
  implicit none

  ! Local Variables
  ! (none yet)

  ! Note: variables shared between propagation and OCT are defined globally in
  ! the fmo_globals_mod module

  character (len=error_l) :: module_name = 'fmo_oct'

  !! @description: Do optimal control

  call getarg(1, rf) ! name of runfolder must be passed as command line argument
  call read_para(para, rf, configfile='config')

  write (*,*) "Starting on "//trim(date_string())
  call print_version_info('fmo_oct')

  call init(para, grid=grid, pulses=pulses)
  call init_ham(ham_x, grid, pulses, para, system='ham_x')
  call init_ham(ham_y, grid, pulses, para, system='ham_y')
  call init_ham(ham_z, grid, pulses, para, system='ham_z')
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

  write(*,'("*** Setting Target ***")')
  call set_oct_target(targets, 1, 3, rho_in, ham_x, grid, rho_tgt)
  call set_oct_target(targets, 2, 3, rho_in, ham_y, grid, rho_tgt)
  call set_oct_target(targets, 3, 3, rho_in, ham_z, grid, rho_tgt)

  write(*,'("*** OCT ***")')

  call open_oct_files()

  call optimize_pulses(targets, pulses, para, J_T=J_T_ss, get_chis=chis_ss, &
  & g_a=g_a_delta_eps_sq, g_b=g_b_zero, oct_info_hook=write_oct_iteration)

  call close_oct_files()

  write (*,'("")')
  write (*,'(A)') "Done: "//trim(date_string())

end program fmo_oct
