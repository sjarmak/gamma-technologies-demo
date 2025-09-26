program mitgcm_demo
  implicit none
  
  ! Command line parameters
  integer :: n, reps
  character(len=32) :: arg
  
  ! Problem size parameters
  integer, parameter :: Nr = 50    ! vertical levels (typical MITgcm)
  real*8, parameter :: pi = 3.141592653589793d0
  
  ! Arrays - simplified to 2D slices (i,k) for demo
  real*8, allocatable :: a(:,:), b(:,:), c(:,:), y(:,:)
  real*8, allocatable :: y_result(:,:)
  
  ! Timing and iteration variables
  integer :: i, k, rep
  real :: start_time, end_time
  
  ! Parse command line
  if (command_argument_count() < 2) then
    write(*,*) 'Usage: mitgcm_demo <n> <reps>'
    stop 1
  endif
  
  call get_command_argument(1, arg)
  read(arg, *) n
  call get_command_argument(2, arg) 
  read(arg, *) reps
  
  ! Allocate arrays
  allocate(a(n,Nr), b(n,Nr), c(n,Nr), y(n,Nr), y_result(n,Nr))
  
  ! Initialize test matrices - tridiagonal system for heat diffusion
  do k = 1, Nr
    do i = 1, n
      ! Lower diagonal (except first row)
      if (k > 1) then
        a(i,k) = -0.5d0
      else
        a(i,k) = 0.0d0
      endif
      
      ! Main diagonal - always positive definite
      b(i,k) = 2.0d0 + 0.1d0 * sin(pi * real(i)/real(n))
      
      ! Upper diagonal (except last row)  
      if (k < Nr) then
        c(i,k) = -0.5d0
      else
        c(i,k) = 0.0d0
      endif
      
      ! RHS - some test function
      y(i,k) = sin(pi * real(i)/real(n)) * cos(pi * real(k)/real(Nr))
    enddo
  enddo
  
  call cpu_time(start_time)
  
  do rep = 1, reps
    ! Copy y to y_result for each iteration
    y_result = y
    
    ! Call the tridiagonal solver
    call solve_tridiagonal_simple(n, Nr, a, b, c, y_result)
  enddo
  
  call cpu_time(end_time)
  
  ! Write output to CSV format
  do i = 1, n
    do k = 1, Nr
      if (k < Nr) then
        write(*,'(F16.10,A)', advance='no') y_result(i,k), ','
      else
        write(*,'(F16.10)') y_result(i,k)
      endif
    enddo
  enddo
  
  ! Write timing info to stderr
  write(0,'(A,F8.4,A)') 'Time per iteration: ', (end_time - start_time) / reps, ' seconds'
  
  deallocate(a, b, c, y, y_result)
end program

subroutine solve_tridiagonal_simple(ni, nk, a, b, c, y)
  implicit none
  integer, intent(in) :: ni, nk
  real*8, intent(in) :: a(ni,nk), b(ni,nk), c(ni,nk)
  real*8, intent(inout) :: y(ni,nk)
  
  ! Local variables
  integer :: i, k
  real*8 :: tmpVar, recVar
  real*8 :: c_prime(ni,nk), y_prime(ni,nk)
  
  ! Forward sweep - Thomas algorithm
  do i = 1, ni
    ! First level
    if (b(i,1) /= 0.0d0) then
      recVar = 1.0d0 / b(i,1)
      c_prime(i,1) = c(i,1) * recVar
      y_prime(i,1) = y(i,1) * recVar
    else
      c_prime(i,1) = 0.0d0
      y_prime(i,1) = 0.0d0
    endif
    
    ! Subsequent levels
    do k = 2, nk
      tmpVar = b(i,k) - a(i,k) * c_prime(i,k-1)
      if (tmpVar /= 0.0d0) then
        recVar = 1.0d0 / tmpVar
        c_prime(i,k) = c(i,k) * recVar
        y_prime(i,k) = (y(i,k) - a(i,k) * y_prime(i,k-1)) * recVar
      else
        c_prime(i,k) = 0.0d0
        y_prime(i,k) = 0.0d0
      endif
    enddo
  enddo
  
  ! Backward sweep
  do i = 1, ni
    ! Last level
    y(i,nk) = y_prime(i,nk)
    
    ! Previous levels
    do k = nk-1, 1, -1
      y(i,k) = y_prime(i,k) - c_prime(i,k) * y(i,k+1)
    enddo
  enddo
end subroutine
