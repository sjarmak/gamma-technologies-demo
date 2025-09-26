program ep_demo
  implicit none
  
  ! Embarrassingly Parallel computation demo
  integer :: n, reps
  character(len=32) :: arg
  real*8, allocatable :: x(:), y(:)
  real*8 :: sum_result
  integer :: i, rep
  real :: start_time, end_time
  
  ! Parse command line
  if (command_argument_count() < 2) then
    write(*,*) 'Usage: ep_demo <n> <reps>'
    stop 1
  endif
  
  call get_command_argument(1, arg)
  read(arg, *) n
  call get_command_argument(2, arg) 
  read(arg, *) reps
  
  allocate(x(n), y(n))
  
  ! Initialize arrays
  do i = 1, n
    x(i) = sin(3.14159d0 * real(i)/real(n))
  enddo
  
  call cpu_time(start_time)
  
  do rep = 1, reps
    ! Embarrassingly parallel operations
    !$OMP PARALLEL DO
    do i = 1, n
      y(i) = exp(x(i)) * cos(x(i)) + x(i)**2
    enddo
    !$OMP END PARALLEL DO
  enddo
  
  call cpu_time(end_time)
  
  ! Output results
  do i = 1, n
    if (i < n) then
      write(*,'(F16.10,A)', advance='no') y(i), ','
    else
      write(*,'(F16.10)') y(i)
    endif
  enddo
  
  write(0,'(A,F8.4,A)') 'Time per iteration: ', (end_time - start_time) / reps, ' seconds'
  
  deallocate(x, y)
end program
