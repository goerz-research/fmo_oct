module fmo_open_close_mod

  use qdyn
  use fmo_globals_mod
  implicit none

  private :: module_name

  public

  character(len=error_l) :: module_name = 'fmo_open_close_mod'

contains

  !! @description: open all files used in propagation (and write header info)
  subroutine open_prop_files()

    integer :: error
    character(len=file_l) :: filename

    character(len=error_l), parameter :: routine_name = "open_prop_files"

    filename = "pop.dat"
    call register_file(filename)
    open(unit=funit(filename), file=join_path(rf, filename), &
    &    action='WRITE', iostat=error)
    call openerror(module_name, 'open_files', error, filename)
    write(funit(filename),'(A1,A14,A18)') '#', 't [fs]', 'populations...'

  end subroutine open_prop_files


  !! @description: close all files opened in `open_prop_files`
  subroutine close_prop_files()

    integer :: error

    character(len=error_l), parameter :: routine_name = "close_prop_files"

    close(unit=funit("pop.dat"), iostat=error)
    call closeerror(module_name, routine_name, error)

  end subroutine close_prop_files


  !! @description: open all files used in OCT (and write header info)
  subroutine open_oct_files()

    integer :: error
    character(len=file_l) :: filename

    character(len=error_l), parameter :: routine_name = "open_oct_files"

    filename = "tau.dat"
    call register_file(filename)
    open(unit=funit(filename), file=join_path(rf, filename), &
    &    action='WRITE', iostat=error)
    call openerror(module_name, routine_name, error, filename)
    write(funit(filename),'(A1,A9,2A15)') '#', 'iter', 'abs(tau)', 'arg(tau)/pi'

    filename = "fluence.dat"
    call register_file(filename)
    open(unit=funit(filename), file=join_path(rf, filename), &
    &    action='WRITE', iostat=error)
    call openerror(module_name, routine_name, error, filename)
    write(funit(filename),'(A1,A9,A25)') '#', 'iter', 'pulse fluence'

  end subroutine open_oct_files


  !! @description: close all files opened in `open_oct_files`
  subroutine close_oct_files()

    integer :: error

    character(len=error_l), parameter :: routine_name = "close_oct_files"

    close(unit=funit("tau.dat"), iostat=error)
    call closeerror(module_name, routine_name, error)
    close(unit=funit("fluence.dat"), iostat=error)
    call closeerror(module_name, routine_name, error)

  end subroutine close_oct_files


end module fmo_open_close_mod
