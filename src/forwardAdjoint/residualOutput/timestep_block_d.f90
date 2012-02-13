   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.6 (r4159) - 21 Sep 2011 10:11
   !
   !  Differentiation of timestep_block in forward (tangent) mode:
   !   variations   of useful results: *radi *radj *radk
   !   with respect to varying inputs: *p *w *si *sj *sk adis
   !   Plus diff mem management of: p:in sfacei:in sfacej:in gamma:in
   !                sfacek:in w:in vol:in si:in sj:in sk:in radi:in
   !                radj:in radk:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          timeStep.f90                                    *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 03-17-2003                                      *
   !      * Last modified: 06-28-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE TIMESTEP_BLOCK_D(onlyradii)
   USE FLOWVARREFSTATE
   USE INPUTITERATION
   USE BLOCKPOINTERS_D
   USE SECTION
   USE INPUTTIMESPECTRAL
   USE INPUTPHYSICS
   USE INPUTDISCRETIZATION
   USE CONSTANTS
   USE ITERATION
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * timeStep computes the time step, or more precisely the time    *
   !      * step divided by the volume per unit CFL, in the owned cells.   *
   !      * However, for the artificial dissipation schemes, the spectral  *
   !      * radIi in the halo's are needed. Therefore the loop is taken    *
   !      * over the the first level of halo cells. The spectral radIi are *
   !      * stored and possibly modified for high aspect ratio cells.      *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Subroutine argument.
   !
   LOGICAL, INTENT(IN) :: onlyradii
   !
   !      Local parameters.
   !
   REAL(kind=realtype), PARAMETER :: b=2.0_realType
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: sps, nn, i, j, k
   REAL(kind=realtype) :: plim, rlim, clim2
   REAL(kind=realtype) :: ux, uy, uz, cc2, qs, sx, sy, sz, rmu
   REAL(kind=realtype) :: uxd, uyd, uzd, cc2d, qsd, sxd, syd, szd
   REAL(kind=realtype) :: ri, rj, rk, rij, rjk, rki
   REAL(kind=realtype) :: rid, rjd, rkd, rijd, rjkd, rkid
   REAL(kind=realtype) :: vsi, vsj, vsk, rfl, dpi, dpj, dpk
   REAL(kind=realtype) :: sface, tmp
   LOGICAL :: radiineeded
   REAL(kind=realtype) :: arg1
   REAL(kind=realtype) :: arg1d
   REAL(kind=realtype) :: result1
   REAL(kind=realtype) :: result1d
   REAL(kind=realtype) :: pwx1
   REAL(kind=realtype) :: pwx1d
   REAL(kind=realtype) :: abs1d
   INTRINSIC MAX
   INTRINSIC ABS
   REAL(kind=realtype) :: abs0d
   REAL(kind=realtype) :: abs5
   REAL(kind=realtype) :: abs4
   REAL(kind=realtype) :: abs3
   REAL(kind=realtype) :: abs2
   REAL(kind=realtype) :: abs2d
   REAL(kind=realtype) :: abs1
   REAL(kind=realtype) :: abs0
   INTRINSIC SQRT
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Determine whether or not the spectral radii are needed for the
   ! flux computation.
   radiineeded = radiineededcoarse
   IF (currentlevel .LE. groundlevel) radiineeded = radiineededfine
   ! Return immediately if only the spectral radii must be computed
   ! and these are not needed for the flux computation.
   IF (onlyradii .AND. (.NOT.radiineeded)) THEN
   radid = 0.0
   radjd = 0.0
   radkd = 0.0
   RETURN
   ELSE
   ! Set the value of plim. To be fully consistent this must have
   ! the dimension of a pressure. Therefore a fraction of pInfCorr
   ! is used. Idem for rlim; compute clim2 as well.
   plim = 0.001_realType*pinfcorr
   rlim = 0.001_realType*rhoinf
   clim2 = 0.000001_realType*gammainf*pinfcorr/rhoinf
   ! Loop over the number of spectral solutions and local blocks.
   ! Initialize sFace to zero. This value will be used if the
   ! block is not moving.
   sface = zero
   !
   !          **************************************************************
   !          *                                                            *
   !          * Inviscid contribution, depending on the preconditioner.    *
   !          * Compute the cell centered values of the spectral radii.    *
   !          *                                                            *
   !          **************************************************************
   !
   SELECT CASE  (precond) 
   CASE (noprecond) 
   radid = 0.0
   radjd = 0.0
   radkd = 0.0
   ! No preconditioner. Simply the standard spectral radius.
   ! Loop over the cells, including the first level halo.
   DO k=1,ke
   DO j=1,je
   DO i=1,ie
   ! Compute the velocities and speed of sound squared.
   uxd = wd(i, j, k, ivx)
   ux = w(i, j, k, ivx)
   uyd = wd(i, j, k, ivy)
   uy = w(i, j, k, ivy)
   uzd = wd(i, j, k, ivz)
   uz = w(i, j, k, ivz)
   cc2d = (gamma(i, j, k)*pd(i, j, k)*w(i, j, k, irho)-gamma(i&
   &              , j, k)*p(i, j, k)*wd(i, j, k, irho))/w(i, j, k, irho)**2
   cc2 = gamma(i, j, k)*p(i, j, k)/w(i, j, k, irho)
   !cc2 = max(cc2,clim2)
   ! Set the dot product of the grid velocity and the
   ! normal in i-direction for a moving face. To avoid
   ! a number of multiplications by 0.5 simply the sum
   ! is taken.
   IF (addgridvelocities) sface = sfacei(i-1, j, k) + sfacei(i&
   &                , j, k)
   ! Spectral radius in i-direction.
   sxd = sid(i-1, j, k, 1) + sid(i, j, k, 1)
   sx = si(i-1, j, k, 1) + si(i, j, k, 1)
   syd = sid(i-1, j, k, 2) + sid(i, j, k, 2)
   sy = si(i-1, j, k, 2) + si(i, j, k, 2)
   szd = sid(i-1, j, k, 3) + sid(i, j, k, 3)
   sz = si(i-1, j, k, 3) + si(i, j, k, 3)
   qsd = uxd*sx + ux*sxd + uyd*sy + uy*syd + uzd*sz + uz*szd
   qs = ux*sx + uy*sy + uz*sz - sface
   IF (qs .GE. 0.) THEN
   abs0d = qsd
   abs0 = qs
   ELSE
   abs0d = -qsd
   abs0 = -qs
   END IF
   arg1d = cc2d*(sx**2+sy**2+sz**2) + cc2*(2*sx*sxd+2*sy*syd+2*&
   &              sz*szd)
   arg1 = cc2*(sx**2+sy**2+sz**2)
   IF (arg1 .EQ. 0.0) THEN
   result1d = 0.0
   ELSE
   result1d = arg1d/(2.0*SQRT(arg1))
   END IF
   result1 = SQRT(arg1)
   radid(i, j, k) = half*(abs0d+result1d)
   radi(i, j, k) = half*(abs0+result1)
   ! The grid velocity in j-direction.
   IF (addgridvelocities) sface = sfacej(i, j-1, k) + sfacej(i&
   &                , j, k)
   ! Spectral radius in j-direction.
   sxd = sjd(i, j-1, k, 1) + sjd(i, j, k, 1)
   sx = sj(i, j-1, k, 1) + sj(i, j, k, 1)
   syd = sjd(i, j-1, k, 2) + sjd(i, j, k, 2)
   sy = sj(i, j-1, k, 2) + sj(i, j, k, 2)
   szd = sjd(i, j-1, k, 3) + sjd(i, j, k, 3)
   sz = sj(i, j-1, k, 3) + sj(i, j, k, 3)
   qsd = uxd*sx + ux*sxd + uyd*sy + uy*syd + uzd*sz + uz*szd
   qs = ux*sx + uy*sy + uz*sz - sface
   IF (qs .GE. 0.) THEN
   abs1d = qsd
   abs1 = qs
   ELSE
   abs1d = -qsd
   abs1 = -qs
   END IF
   arg1d = cc2d*(sx**2+sy**2+sz**2) + cc2*(2*sx*sxd+2*sy*syd+2*&
   &              sz*szd)
   arg1 = cc2*(sx**2+sy**2+sz**2)
   IF (arg1 .EQ. 0.0) THEN
   result1d = 0.0
   ELSE
   result1d = arg1d/(2.0*SQRT(arg1))
   END IF
   result1 = SQRT(arg1)
   radjd(i, j, k) = half*(abs1d+result1d)
   radj(i, j, k) = half*(abs1+result1)
   ! The grid velocity in k-direction.
   IF (addgridvelocities) sface = sfacek(i, j, k-1) + sfacek(i&
   &                , j, k)
   ! Spectral radius in k-direction.
   sxd = skd(i, j, k-1, 1) + skd(i, j, k, 1)
   sx = sk(i, j, k-1, 1) + sk(i, j, k, 1)
   syd = skd(i, j, k-1, 2) + skd(i, j, k, 2)
   sy = sk(i, j, k-1, 2) + sk(i, j, k, 2)
   szd = skd(i, j, k-1, 3) + skd(i, j, k, 3)
   sz = sk(i, j, k-1, 3) + sk(i, j, k, 3)
   qsd = uxd*sx + ux*sxd + uyd*sy + uy*syd + uzd*sz + uz*szd
   qs = ux*sx + uy*sy + uz*sz - sface
   IF (qs .GE. 0.) THEN
   abs2d = qsd
   abs2 = qs
   ELSE
   abs2d = -qsd
   abs2 = -qs
   END IF
   arg1d = cc2d*(sx**2+sy**2+sz**2) + cc2*(2*sx*sxd+2*sy*syd+2*&
   &              sz*szd)
   arg1 = cc2*(sx**2+sy**2+sz**2)
   IF (arg1 .EQ. 0.0) THEN
   result1d = 0.0
   ELSE
   result1d = arg1d/(2.0*SQRT(arg1))
   END IF
   result1 = SQRT(arg1)
   radkd(i, j, k) = half*(abs2d+result1d)
   radk(i, j, k) = half*(abs2+result1)
   ! Compute the inviscid contribution to the time step.
   dtld(i, j, k) = 0.0
   dtl(i, j, k) = radi(i, j, k) + radj(i, j, k) + radk(i, j, k)
   END DO
   END DO
   END DO
   CASE (turkel) 
   CALL TERMINATE('timeStep', &
   &                  'Turkel preconditioner not implemented yet')
   radid = 0.0
   radjd = 0.0
   radkd = 0.0
   CASE (choimerkle) 
   CALL TERMINATE('timeStep', &
   &                  'choi merkle preconditioner not implemented yet')
   radid = 0.0
   radjd = 0.0
   radkd = 0.0
   CASE DEFAULT
   radid = 0.0
   radjd = 0.0
   radkd = 0.0
   END SELECT
   !
   !          **************************************************************
   !          *                                                            *
   !          * Adapt the spectral radii if directional scaling must be    *
   !          * applied.                                                   *
   !          *                                                            *
   !          **************************************************************
   !
   IF (dirscaling .AND. currentlevel .LE. groundlevel) THEN
   ! if( dirScaling ) then
   DO k=1,ke
   DO j=1,je
   DO i=1,ie
   IF (radi(i, j, k) .LT. eps) THEN
   ri = eps
   rid = 0.0
   ELSE
   rid = radid(i, j, k)
   ri = radi(i, j, k)
   END IF
   IF (radj(i, j, k) .LT. eps) THEN
   rj = eps
   rjd = 0.0
   ELSE
   rjd = radjd(i, j, k)
   rj = radj(i, j, k)
   END IF
   IF (radk(i, j, k) .LT. eps) THEN
   rk = eps
   rkd = 0.0
   ELSE
   rkd = radkd(i, j, k)
   rk = radk(i, j, k)
   END IF
   ! Compute the scaling in the three coordinate
   ! directions.
   pwx1d = (rid*rj-ri*rjd)/rj**2
   pwx1 = ri/rj
   IF (pwx1 .GT. 0.0 .OR. (pwx1 .LT. 0.0 .AND. adis .EQ. INT(&
   &                adis))) THEN
   rijd = adis*pwx1**(adis-1)*pwx1d
   ELSE IF (pwx1 .EQ. 0.0 .AND. adis .EQ. 1.0) THEN
   rijd = pwx1d
   ELSE
   rijd = 0.0
   END IF
   rij = pwx1**adis
   pwx1d = (rjd*rk-rj*rkd)/rk**2
   pwx1 = rj/rk
   IF (pwx1 .GT. 0.0 .OR. (pwx1 .LT. 0.0 .AND. adis .EQ. INT(&
   &                adis))) THEN
   rjkd = adis*pwx1**(adis-1)*pwx1d
   ELSE IF (pwx1 .EQ. 0.0 .AND. adis .EQ. 1.0) THEN
   rjkd = pwx1d
   ELSE
   rjkd = 0.0
   END IF
   rjk = pwx1**adis
   pwx1d = (rkd*ri-rk*rid)/ri**2
   pwx1 = rk/ri
   IF (pwx1 .GT. 0.0 .OR. (pwx1 .LT. 0.0 .AND. adis .EQ. INT(&
   &                adis))) THEN
   rkid = adis*pwx1**(adis-1)*pwx1d
   ELSE IF (pwx1 .EQ. 0.0 .AND. adis .EQ. 1.0) THEN
   rkid = pwx1d
   ELSE
   rkid = 0.0
   END IF
   rki = pwx1**adis
   ! Create the scaled versions of the aspect ratios.
   ! Note that the multiplication is done with radi, radJ
   ! and radK, such that the influence of the clipping
   ! is negligible.
   !   radi(i,j,k) = third*radi(i,j,k)*(one + one/rij + rki)
   !   radJ(i,j,k) = third*radJ(i,j,k)*(one + one/rjk + rij)
   !   radK(i,j,k) = third*radK(i,j,k)*(one + one/rki + rjk)
   radid(i, j, k) = radid(i, j, k)*(one+one/rij+rki) + radi(i, &
   &              j, k)*(rkid-one*rijd/rij**2)
   radi(i, j, k) = radi(i, j, k)*(one+one/rij+rki)
   radjd(i, j, k) = radjd(i, j, k)*(one+one/rjk+rij) + radj(i, &
   &              j, k)*(rijd-one*rjkd/rjk**2)
   radj(i, j, k) = radj(i, j, k)*(one+one/rjk+rij)
   radkd(i, j, k) = radkd(i, j, k)*(one+one/rki+rjk) + radk(i, &
   &              j, k)*(rjkd-one*rkid/rki**2)
   radk(i, j, k) = radk(i, j, k)*(one+one/rki+rjk)
   END DO
   END DO
   END DO
   END IF
   ! The rest of this file can be skipped if only the spectral
   ! radii need to be computed.
   IF (.NOT.onlyradii) THEN
   ! The viscous contribution, if needed.
   IF (viscous) THEN
   ! Loop over the owned cell centers.
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   ! Compute the effective viscosity coefficient. The
   ! factor 0.5 is a combination of two things. In the
   ! standard central discretization of a second
   ! derivative there is a factor 2 multiplying the
   ! central node. However in the code below not the
   ! average but the sum of the left and the right face
   ! is taken and squared. This leads to a factor 4.
   ! Combining both effects leads to 0.5. Furthermore,
   ! it is divided by the volume and density to obtain
   ! the correct dimensions and multiplied by the
   ! non-dimensional factor factVis.
   rmu = rlv(i, j, k)
   IF (eddymodel) rmu = rmu + rev(i, j, k)
   rmu = half*rmu/(w(i, j, k, irho)*vol(i, j, k))
   ! Add the viscous contribution in i-direction to the
   ! (inverse) of the time step.
   sx = si(i, j, k, 1) + si(i-1, j, k, 1)
   sy = si(i, j, k, 2) + si(i-1, j, k, 2)
   sz = si(i, j, k, 3) + si(i-1, j, k, 3)
   vsi = rmu*(sx*sx+sy*sy+sz*sz)
   dtld(i, j, k) = 0.0
   dtl(i, j, k) = dtl(i, j, k) + vsi
   ! Add the viscous contribution in j-direction to the
   ! (inverse) of the time step.
   sx = sj(i, j, k, 1) + sj(i, j-1, k, 1)
   sy = sj(i, j, k, 2) + sj(i, j-1, k, 2)
   sz = sj(i, j, k, 3) + sj(i, j-1, k, 3)
   vsj = rmu*(sx*sx+sy*sy+sz*sz)
   dtld(i, j, k) = 0.0
   dtl(i, j, k) = dtl(i, j, k) + vsj
   ! Add the viscous contribution in k-direction to the
   ! (inverse) of the time step.
   sx = sk(i, j, k, 1) + sk(i, j, k-1, 1)
   sy = sk(i, j, k, 2) + sk(i, j, k-1, 2)
   sz = sk(i, j, k, 3) + sk(i, j, k-1, 3)
   vsk = rmu*(sx*sx+sy*sy+sz*sz)
   dtld(i, j, k) = 0.0
   dtl(i, j, k) = dtl(i, j, k) + vsk
   END DO
   END DO
   END DO
   END IF
   ! For the spectral mode an additional term term must be
   ! taken into account, which corresponds to the contribution
   ! of the highest frequency.
   IF (equationmode .EQ. timespectral) THEN
   tmp = ntimeintervalsspectral*pi*timeref/sections(sectionid)%&
   &          timeperiod
   ! Loop over the owned cell centers and add the term.
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   dtld(i, j, k) = 0.0
   dtl(i, j, k) = dtl(i, j, k) + tmp*vol(i, j, k)
   END DO
   END DO
   END DO
   END IF
   ! Currently the inverse of dt/vol is stored in dtl. Invert
   ! this value such that the time step per unit cfl number is
   ! stored and correct in cases of high gradients.
   DO k=2,kl
   DO j=2,jl
   DO i=2,il
   IF (p(i+1, j, k) - two*p(i, j, k) + p(i-1, j, k) .GE. 0.) &
   &            THEN
   abs3 = p(i+1, j, k) - two*p(i, j, k) + p(i-1, j, k)
   ELSE
   abs3 = -(p(i+1, j, k)-two*p(i, j, k)+p(i-1, j, k))
   END IF
   dpi = abs3/(p(i+1, j, k)+two*p(i, j, k)+p(i-1, j, k)+plim)
   IF (p(i, j+1, k) - two*p(i, j, k) + p(i, j-1, k) .GE. 0.) &
   &            THEN
   abs4 = p(i, j+1, k) - two*p(i, j, k) + p(i, j-1, k)
   ELSE
   abs4 = -(p(i, j+1, k)-two*p(i, j, k)+p(i, j-1, k))
   END IF
   dpj = abs4/(p(i, j+1, k)+two*p(i, j, k)+p(i, j-1, k)+plim)
   IF (p(i, j, k+1) - two*p(i, j, k) + p(i, j, k-1) .GE. 0.) &
   &            THEN
   abs5 = p(i, j, k+1) - two*p(i, j, k) + p(i, j, k-1)
   ELSE
   abs5 = -(p(i, j, k+1)-two*p(i, j, k)+p(i, j, k-1))
   END IF
   dpk = abs5/(p(i, j, k+1)+two*p(i, j, k)+p(i, j, k-1)+plim)
   rfl = one/(one+b*(dpi+dpj+dpk))
   dtld(i, j, k) = 0.0
   dtl(i, j, k) = rfl/dtl(i, j, k)
   END DO
   END DO
   END DO
   END IF
   END IF
   END SUBROUTINE TIMESTEP_BLOCK_D
