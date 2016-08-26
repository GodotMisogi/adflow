!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of computepressuresimple in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: *p *w
!   with respect to varying inputs: *p *w
!   rw status of diff variables: *p:in-out *w:incr
!   plus diff mem management of: p:in w:in
! compute the pressure on a block with the pointers already set. this
! routine is used by the forward mode ad code only. 
subroutine computepressuresimple_fast_b()
  use constants
  use blockpointers
  use flowvarrefstate
  use inputphysics
  implicit none
! local variables
  integer(kind=inttype) :: i, j, k, ii
  real(kind=realtype) :: gm1, v2
  real(kind=realtype) :: v2d
  intrinsic mod
  intrinsic max
  real(kind=realtype) :: tempd
! compute the pressures
  gm1 = gammaconstant - one
  do ii=0,(ib+1)*(jb+1)*(kb+1)-1
    i = mod(ii, ib + 1)
    j = mod(ii/(ib+1), jb + 1)
    k = ii/((ib+1)*(jb+1))
    v2 = w(i, j, k, ivx)**2 + w(i, j, k, ivy)**2 + w(i, j, k, ivz)**2
    p(i, j, k) = gm1*(w(i, j, k, irhoe)-half*w(i, j, k, irho)*v2)
    if (p(i, j, k) .lt. 1.e-4_realtype*pinfcorr) pd(i, j, k) = 0.0_8
    tempd = gm1*pd(i, j, k)
    wd(i, j, k, irhoe) = wd(i, j, k, irhoe) + tempd
    wd(i, j, k, irho) = wd(i, j, k, irho) - half*v2*tempd
    v2d = -(half*w(i, j, k, irho)*tempd)
    pd(i, j, k) = 0.0_8
    wd(i, j, k, ivx) = wd(i, j, k, ivx) + 2*w(i, j, k, ivx)*v2d
    wd(i, j, k, ivy) = wd(i, j, k, ivy) + 2*w(i, j, k, ivy)*v2d
    wd(i, j, k, ivz) = wd(i, j, k, ivz) + 2*w(i, j, k, ivz)*v2d
  end do
end subroutine computepressuresimple_fast_b
