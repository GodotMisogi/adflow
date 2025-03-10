!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module walldistance_d
  use constants, only : inttype, realtype
  use walldistancedata
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------
  save 

contains
!  differentiation of updatewalldistancesquickly in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: *d2wall
!   with respect to varying inputs: *x *d2wall *xsurf
!   rw status of diff variables: *x:in *d2wall:in-out *xsurf:in
!   plus diff mem management of: x:in d2wall:in xsurf:in
  subroutine updatewalldistancesquickly_d(nn, level, sps)
! this is the actual update routine that uses xsurf. it is done on
! block-level-sps basis.  this is the used to update the wall
! distance. most importantly, this routine is included in the
! reverse mode ad routines, but not the forward mode. since it is
! done on a per-block basis, it is assumed that the required block
! pointers are already set.
    use constants
    use blockpointers, only : nx, ny, nz, il, jl, kl, x, xd, flowdoms,&
&   flowdomsd, d2wall, d2walld
    implicit none
! subroutine arguments
    integer(kind=inttype) :: nn, level, sps
! local variables
    integer(kind=inttype) :: i, j, k, ii, ind(4)
    real(kind=realtype) :: xp(3), xc(3), u, v
    real(kind=realtype) :: xpd(3), xcd(3)
    intrinsic sqrt
    real(kind=realtype) :: arg1
    real(kind=realtype) :: arg1d
    xcd = 0.0_8
    do k=2,kl
      do j=2,jl
        do i=2,il
          if (flowdoms(nn, level, sps)%surfnodeindices(1, i, j, k) .eq. &
&             0) then
! this node is too far away and has no
! association. set the distance to a large constant.
            d2walld(i, j, k) = 0.0_8
            d2wall(i, j, k) = large
          else
! extract elemid and u-v position for the association of
! this cell:
            ind = flowdoms(nn, level, sps)%surfnodeindices(:, i, j, k)
            u = flowdoms(nn, level, sps)%uv(1, i, j, k)
            v = flowdoms(nn, level, sps)%uv(2, i, j, k)
! now we have the 4 corners, use bi-linear shape
! functions o to get target: (ccw ordering remember!)
            xpd(:) = (one-u)*(one-v)*xsurfd(3*(ind(1)-1)+1:3*ind(1)) + u&
&             *(one-v)*xsurfd(3*(ind(2)-1)+1:3*ind(2)) + u*v*xsurfd(3*(&
&             ind(3)-1)+1:3*ind(3)) + (one-u)*v*xsurfd(3*(ind(4)-1)+1:3*&
&             ind(4))
            xp(:) = (one-u)*(one-v)*xsurf(3*(ind(1)-1)+1:3*ind(1)) + u*(&
&             one-v)*xsurf(3*(ind(2)-1)+1:3*ind(2)) + u*v*xsurf(3*(ind(3&
&             )-1)+1:3*ind(3)) + (one-u)*v*xsurf(3*(ind(4)-1)+1:3*ind(4)&
&             )
! get the cell center
            xcd(1) = eighth*(xd(i-1, j-1, k-1, 1)+xd(i, j-1, k-1, 1)+xd(&
&             i-1, j, k-1, 1)+xd(i, j, k-1, 1)+xd(i-1, j-1, k, 1)+xd(i, &
&             j-1, k, 1)+xd(i-1, j, k, 1)+xd(i, j, k, 1))
            xc(1) = eighth*(x(i-1, j-1, k-1, 1)+x(i, j-1, k-1, 1)+x(i-1&
&             , j, k-1, 1)+x(i, j, k-1, 1)+x(i-1, j-1, k, 1)+x(i, j-1, k&
&             , 1)+x(i-1, j, k, 1)+x(i, j, k, 1))
            xcd(2) = eighth*(xd(i-1, j-1, k-1, 2)+xd(i, j-1, k-1, 2)+xd(&
&             i-1, j, k-1, 2)+xd(i, j, k-1, 2)+xd(i-1, j-1, k, 2)+xd(i, &
&             j-1, k, 2)+xd(i-1, j, k, 2)+xd(i, j, k, 2))
            xc(2) = eighth*(x(i-1, j-1, k-1, 2)+x(i, j-1, k-1, 2)+x(i-1&
&             , j, k-1, 2)+x(i, j, k-1, 2)+x(i-1, j-1, k, 2)+x(i, j-1, k&
&             , 2)+x(i-1, j, k, 2)+x(i, j, k, 2))
            xcd(3) = eighth*(xd(i-1, j-1, k-1, 3)+xd(i, j-1, k-1, 3)+xd(&
&             i-1, j, k-1, 3)+xd(i, j, k-1, 3)+xd(i-1, j-1, k, 3)+xd(i, &
&             j-1, k, 3)+xd(i-1, j, k, 3)+xd(i, j, k, 3))
            xc(3) = eighth*(x(i-1, j-1, k-1, 3)+x(i, j-1, k-1, 3)+x(i-1&
&             , j, k-1, 3)+x(i, j, k-1, 3)+x(i-1, j-1, k, 3)+x(i, j-1, k&
&             , 3)+x(i-1, j, k, 3)+x(i, j, k, 3))
! now we have the two points...just take the norm of the
! distance between them
            arg1d = 2*(xc(1)-xp(1))*(xcd(1)-xpd(1)) + 2*(xc(2)-xp(2))*(&
&             xcd(2)-xpd(2)) + 2*(xc(3)-xp(3))*(xcd(3)-xpd(3))
            arg1 = (xc(1)-xp(1))**2 + (xc(2)-xp(2))**2 + (xc(3)-xp(3))**&
&             2
            if (arg1 .eq. 0.0_8) then
              d2walld(i, j, k) = 0.0_8
            else
              d2walld(i, j, k) = arg1d/(2.0*sqrt(arg1))
            end if
            d2wall(i, j, k) = sqrt(arg1)
          end if
        end do
      end do
    end do
  end subroutine updatewalldistancesquickly_d
  subroutine updatewalldistancesquickly(nn, level, sps)
! this is the actual update routine that uses xsurf. it is done on
! block-level-sps basis.  this is the used to update the wall
! distance. most importantly, this routine is included in the
! reverse mode ad routines, but not the forward mode. since it is
! done on a per-block basis, it is assumed that the required block
! pointers are already set.
    use constants
    use blockpointers, only : nx, ny, nz, il, jl, kl, x, flowdoms, &
&   d2wall
    implicit none
! subroutine arguments
    integer(kind=inttype) :: nn, level, sps
! local variables
    integer(kind=inttype) :: i, j, k, ii, ind(4)
    real(kind=realtype) :: xp(3), xc(3), u, v
    intrinsic sqrt
    real(kind=realtype) :: arg1
    do k=2,kl
      do j=2,jl
        do i=2,il
          if (flowdoms(nn, level, sps)%surfnodeindices(1, i, j, k) .eq. &
&             0) then
! this node is too far away and has no
! association. set the distance to a large constant.
            d2wall(i, j, k) = large
          else
! extract elemid and u-v position for the association of
! this cell:
            ind = flowdoms(nn, level, sps)%surfnodeindices(:, i, j, k)
            u = flowdoms(nn, level, sps)%uv(1, i, j, k)
            v = flowdoms(nn, level, sps)%uv(2, i, j, k)
! now we have the 4 corners, use bi-linear shape
! functions o to get target: (ccw ordering remember!)
            xp(:) = (one-u)*(one-v)*xsurf(3*(ind(1)-1)+1:3*ind(1)) + u*(&
&             one-v)*xsurf(3*(ind(2)-1)+1:3*ind(2)) + u*v*xsurf(3*(ind(3&
&             )-1)+1:3*ind(3)) + (one-u)*v*xsurf(3*(ind(4)-1)+1:3*ind(4)&
&             )
! get the cell center
            xc(1) = eighth*(x(i-1, j-1, k-1, 1)+x(i, j-1, k-1, 1)+x(i-1&
&             , j, k-1, 1)+x(i, j, k-1, 1)+x(i-1, j-1, k, 1)+x(i, j-1, k&
&             , 1)+x(i-1, j, k, 1)+x(i, j, k, 1))
            xc(2) = eighth*(x(i-1, j-1, k-1, 2)+x(i, j-1, k-1, 2)+x(i-1&
&             , j, k-1, 2)+x(i, j, k-1, 2)+x(i-1, j-1, k, 2)+x(i, j-1, k&
&             , 2)+x(i-1, j, k, 2)+x(i, j, k, 2))
            xc(3) = eighth*(x(i-1, j-1, k-1, 3)+x(i, j-1, k-1, 3)+x(i-1&
&             , j, k-1, 3)+x(i, j, k-1, 3)+x(i-1, j-1, k, 3)+x(i, j-1, k&
&             , 3)+x(i-1, j, k, 3)+x(i, j, k, 3))
! now we have the two points...just take the norm of the
! distance between them
            arg1 = (xc(1)-xp(1))**2 + (xc(2)-xp(2))**2 + (xc(3)-xp(3))**&
&             2
            d2wall(i, j, k) = sqrt(arg1)
          end if
        end do
      end do
    end do
  end subroutine updatewalldistancesquickly
end module walldistance_d
