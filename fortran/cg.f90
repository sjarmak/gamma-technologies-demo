program cg_demo
  implicit none
  
  ! Simple Conjugate Gradient iteration demo
  integer :: n, reps
  character(len=32) :: arg
  real*8, allocatable :: A(:,:), x(:), b(:), r(:), p(:), Ap(:)
  real*8 :: alpha, beta, rsold, rsnew, pAp
  integer :: i, j, rep, iter
  real :: start_time, end_time
  
  ! Parse command line
  if (command_argument_count() < 2) then
    write(*,*) 'Usage: cg_demo <n> <reps>'
    stop 1
  endif
  
  call get_command_argument(1, arg)
  read(arg, *) n
  call get_command_argument(2, arg) 
  read(arg, *) reps
  
  allocate(A(n,n), x(n), b(n), r(n), p(n), Ap(n))
  
  ! Initialize - simple symmetric positive definite matrix
  do i = 1, n
    do j = 1, n
      if (i == j) then
        A(i,j) = 4.0d0
      else if (abs(i-j) == 1) then
        A(i,j) = -1.0d0
      else
        A(i,j) = 0.0d0
      endif
    enddo
    b(i) = sin(3.14159d0 * real(i)/real(n))
    x(i) = 0.0d0
  enddo
  
  call cpu_time(start_time)
  
  do rep = 1, reps
    x = 0.0d0
    ! Simple CG iteration
    r = b
    p = r
    rsold = dot_product(r, r)
    
    do iter = 1, min(10, n)  ! Limited iterations for demo
      ! Ap = A * p
      do i = 1, n
        Ap(i) = dot_product(A(i,:), p)
      enddo
      
      pAp = dot_product(p, Ap)
      if (pAp > 1e-14) then
        alpha = rsold / pAp
      else
        exit
      endif
      
      x = x + alpha * p
      r = r - alpha * Ap
      rsnew = dot_product(r, r)
      
      if (sqrt(rsnew) < 1e-10) exit
      
      beta = rsnew / rsold
      p = r + beta * p
      rsold = rsnew
    enddo
  enddo
  
  call cpu_time(end_time)
  
  ! Output solution
  do i = 1, n
    if (i < n) then
      write(*,'(F16.10,A)', advance='no') x(i), ','
    else
      write(*,'(F16.10)') x(i)
    endif
  enddo
  
  write(0,'(A,F8.4,A)') 'Time per iteration: ', (end_time - start_time) / reps, ' seconds'
  
  deallocate(A, x, b, r, p, Ap)
end program
