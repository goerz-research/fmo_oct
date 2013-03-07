program fmo_write_pulses

  use qdyn
  use fmo_globals_mod

  implicit none

  character(len=error_l) :: module_name = 'fmo_write_pulses'

  !! @description: Read pulse from the config file, and write  out to
  !!               pulse.dat in the runfolder

  call getarg(1, rf)
  call read_para(para, rf, configfile=config_filename)
  call init(para, pulses=pulses)
  call write_pulse(pulses(1), join_path(rf, 'pulse.dat'), time_unit="fs")

end program fmo_write_pulses
