!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module initializeflow_b
  use constants, only : inttype, realtype, maxstringlen
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------
  save 

contains
!  differentiation of referencestate in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: mach veldirfreestream machcoef
!                tinfdim pinf timeref rhoinf muref rhoinfdim tref
!                winf muinf uinf pinfcorr rgas pinfdim pref rhoref
!   with respect to varying inputs: mach veldirfreestream machcoef
!                tinfdim pinf timeref rhoinf muref rhoinfdim tref
!                winf muinf uinf pinfcorr rgas pinfdim pref rhoref
!   rw status of diff variables: mach:incr veldirfreestream:incr
!                machcoef:incr tinfdim:incr pinf:in-zero timeref:in-zero
!                rhoinf:in-zero muref:in-zero rhoinfdim:incr tref:in-zero
!                winf:in-zero muinf:in-zero uinf:in-zero pinfcorr:in-zero
!                rgas:in-zero muinfdim:(loc) pinfdim:incr pref:in-zero
!                rhoref:in-zero
  subroutine referencestate_b()
!
!       the original version has been nuked since the computations are
!       no longer necessary when calling from python
!       this is the most compliclated routine in all of adflow. it is
!       stupidly complicated. this is most likely the reason your
!       derivatives are wrong. you don't understand this routine
!       and its effects.
!       this routine *requries* the following as input:
!       mach, pinfdim, tinfdim, rhoinfdim, rgasdim (machcoef non-sa
!        turbulence only)
!       optionally, pref, rhoref and tref are used if they are
!       are non-negative. this only happens when you want the equations
!       normalized by values other than the freestream
!      * this routine computes as output:
!      *   muinfdim, (unused anywhere in code)
!         pref, rhoref, tref, muref, timeref ('dimensional' reference)
!         pinf, pinfcorr, rhoinf, uinf, rgas, muinf, gammainf and winf
!         (non-dimensionalized values used in actual computations)
!
    use constants
    use paramturb
    use inputphysics, only : equations, mach, machd, machcoef, &
&   machcoefd, musuthdim, tsuthdim, veldirfreestream, veldirfreestreamd,&
&   rgasdim, ssuthdim, eddyvisinfratio, turbmodel, turbintensityinf
    use flowvarrefstate, only : pinfdim, pinfdimd, tinfdim, tinfdimd, &
&   rhoinfdim, rhoinfdimd, muinfdim, muinfdimd, pref, prefd, rhoref, &
&   rhorefd, tref, trefd, muref, murefd, timeref, timerefd, uref, href, &
&   pinf, pinfd, pinfcorr, pinfcorrd, rhoinf, rhoinfd, uinf, uinfd, rgas&
&   , rgasd, muinf, muinfd, gammainf, winf, winfd, nw, nwf, kpresent, &
&   winf, winfd
    use flowutils_b, only : computegamma, etot, etot_b
    use turbutils_b, only : sanuknowneddyratio, sanuknowneddyratio_b
    implicit none
    integer(kind=inttype) :: sps, nn, mm, ierr
    real(kind=realtype) :: gm1, ratio
    real(kind=realtype) :: nuinf, ktmp, uinf2
    real(kind=realtype) :: nuinfd, ktmpd, uinf2d
    real(kind=realtype) :: vinf, zinf, tmp1(1), tmp2(1)
    real(kind=realtype) :: vinfd, zinfd
    intrinsic sqrt
    real(kind=realtype) :: tmp
    real(kind=realtype) :: tmp0
    real(kind=realtype) :: tmp3
    real(kind=realtype) :: tmp4
    integer :: branch
    real(kind=realtype) :: temp0
    real(kind=realtype) :: tmpd
    real(kind=realtype) :: tempd
    real(kind=realtype) :: tempd8
    real(kind=realtype) :: tempd7
    real(kind=realtype) :: tempd6
    real(kind=realtype) :: tempd5
    real(kind=realtype) :: tempd4
    real(kind=realtype) :: tempd3
    real(kind=realtype) :: tempd2
    real(kind=realtype) :: tempd1
    real(kind=realtype) :: tempd0
    real(kind=realtype) :: tmpd2
    real(kind=realtype) :: tmpd1
    real(kind=realtype) :: tmpd0
    real(kind=realtype) :: temp
! compute the dimensional viscosity from sutherland's law
    muinfdim = musuthdim*((tsuthdim+ssuthdim)/(tinfdim+ssuthdim))*(&
&     tinfdim/tsuthdim)**1.5_realtype
! set the reference values. they *could* be different from the
! free-stream values for an internal flow simulation. for now,
! we just use the actual free stream values.
    pref = pinfdim
    tref = tinfdim
    rhoref = rhoinfdim
! compute the value of muref, such that the nondimensional
! equations are identical to the dimensional ones.
! note that in the non-dimensionalization of muref there is
! a reference length. however this reference length is 1.0
! in this code, because the coordinates are converted to
! meters.
    muref = sqrt(pref*rhoref)
! compute timeref for a correct nondimensionalization of the
! unsteady equations. some story as for the reference viscosity
! concerning the reference length.
! compute the nondimensional pressure, density, velocity,
! viscosity and gas constant.
    pinf = pinfdim/pref
    rhoinf = rhoinfdim/rhoref
    uinf = mach*sqrt(gammainf*pinf/rhoinf)
    muinf = muinfdim/muref
    call computegamma(tmp1, tmp2, 1)
    call pushreal8(gammainf)
    gammainf = tmp2(1)
! ----------------------------------------
!      compute the final winf
! ----------------------------------------
! allocate the memory for winf if necessary
! zero out the winf first
    winf(:) = zero
! set the reference value of the flow variables, except the total
! energy. this will be computed at the end of this routine.
    winf(irho) = rhoinf
    winf(ivx) = uinf*veldirfreestream(1)
    winf(ivy) = uinf*veldirfreestream(2)
    winf(ivz) = uinf*veldirfreestream(3)
! compute the velocity squared based on machcoef. this gives a
! better indication of the 'speed' of the flow so the turubulence
! intensity ration is more meaningful especially for moving
! geometries. (not used in sa model)
    uinf2 = machcoef*machcoef*gammainf*pinf/rhoinf
! set the turbulent variables if transport variables are to be
! solved. we should be checking for rans equations here,
! however, this code is included in block res. the issue is
! that for frozen turbulence (or ank jacobian) we call the
! block_res with equationtype set to laminar even though we are
! actually solving the rans equations. the issue is that, the
! freestream turb variables will be changed to zero, thus
! changing the solution. insteady we check if nw > nwf which
! will accomplish the same thing.
    if (nw .gt. nwf) then
      nuinf = muinf/rhoinf
      select case  (turbmodel) 
      case (spalartallmaras, spalartallmarasedwards) 
        winf(itu1) = sanuknowneddyratio(eddyvisinfratio, nuinf)
        call pushcontrol3b(1)
      case (komegawilcox, komegamodified, mentersst) 
!=============================================================
        winf(itu1) = 1.5_realtype*uinf2*turbintensityinf**2
        tmp = winf(itu1)/(eddyvisinfratio*nuinf)
        call pushreal8(winf(itu2))
        winf(itu2) = tmp
        call pushcontrol3b(2)
      case (ktau) 
!=============================================================
        winf(itu1) = 1.5_realtype*uinf2*turbintensityinf**2
        tmp0 = eddyvisinfratio*nuinf/winf(itu1)
        call pushreal8(winf(itu2))
        winf(itu2) = tmp0
        call pushcontrol3b(3)
      case (v2f) 
!=============================================================
        winf(itu1) = 1.5_realtype*uinf2*turbintensityinf**2
        tmp3 = 0.09_realtype*winf(itu1)**2/(eddyvisinfratio*nuinf)
        call pushreal8(winf(itu2))
        winf(itu2) = tmp3
        tmp4 = 0.666666_realtype*winf(itu1)
        call pushreal8(winf(itu3))
        winf(itu3) = tmp4
        call pushreal8(winf(itu4))
        winf(itu4) = 0.0_realtype
        call pushcontrol3b(4)
      case default
        call pushcontrol3b(0)
      end select
    else
      call pushcontrol3b(5)
    end if
! set the value of pinfcorr. in case a k-equation is present
! add 2/3 times rho*k.
    pinfcorr = pinf
    if (kpresent) then
      pinfcorr = pinf + two*third*rhoinf*winf(itu1)
      call pushcontrol1b(0)
    else
      call pushcontrol1b(1)
    end if
! compute the free stream total energy.
    ktmp = zero
    if (kpresent) then
      ktmp = winf(itu1)
      call pushcontrol1b(0)
    else
      call pushcontrol1b(1)
    end if
    vinf = zero
    zinf = zero
    vinfd = 0.0_8
    zinfd = 0.0_8
    ktmpd = 0.0_8
    call etot_b(rhoinf, rhoinfd, uinf, uinfd, vinf, vinfd, zinf, zinfd, &
&         pinfcorr, pinfcorrd, ktmp, ktmpd, winf(irhoe), winfd(irhoe), &
&         kpresent)
    call popcontrol1b(branch)
    if (branch .eq. 0) winfd(itu1) = winfd(itu1) + ktmpd
    call popcontrol1b(branch)
    if (branch .eq. 0) then
      tempd8 = two*third*pinfcorrd
      pinfd = pinfd + pinfcorrd
      rhoinfd = rhoinfd + winf(itu1)*tempd8
      winfd(itu1) = winfd(itu1) + rhoinf*tempd8
      pinfcorrd = 0.0_8
    end if
    pinfd = pinfd + pinfcorrd
    call popcontrol3b(branch)
    if (branch .lt. 3) then
      if (branch .eq. 0) then
        uinf2d = 0.0_8
        nuinfd = 0.0_8
      else if (branch .eq. 1) then
        call sanuknowneddyratio_b(eddyvisinfratio, nuinf, nuinfd, winfd(&
&                           itu1))
        winfd(itu1) = 0.0_8
        uinf2d = 0.0_8
      else
        call popreal8(winf(itu2))
        tmpd = winfd(itu2)
        winfd(itu2) = 0.0_8
        tempd5 = tmpd/(eddyvisinfratio*nuinf)
        winfd(itu1) = winfd(itu1) + tempd5
        nuinfd = -(winf(itu1)*tempd5/nuinf)
        uinf2d = turbintensityinf**2*1.5_realtype*winfd(itu1)
        winfd(itu1) = 0.0_8
      end if
    else if (branch .eq. 3) then
      call popreal8(winf(itu2))
      tmpd0 = winfd(itu2)
      winfd(itu2) = 0.0_8
      tempd6 = eddyvisinfratio*tmpd0/winf(itu1)
      nuinfd = tempd6
      winfd(itu1) = winfd(itu1) - nuinf*tempd6/winf(itu1)
      uinf2d = turbintensityinf**2*1.5_realtype*winfd(itu1)
      winfd(itu1) = 0.0_8
    else if (branch .eq. 4) then
      call popreal8(winf(itu4))
      winfd(itu4) = 0.0_8
      call popreal8(winf(itu3))
      tmpd1 = winfd(itu3)
      winfd(itu3) = 0.0_8
      winfd(itu1) = winfd(itu1) + 0.666666_realtype*tmpd1
      call popreal8(winf(itu2))
      tmpd2 = winfd(itu2)
      winfd(itu2) = 0.0_8
      tempd7 = 0.09_realtype*tmpd2/(eddyvisinfratio*nuinf)
      winfd(itu1) = winfd(itu1) + 2*winf(itu1)*tempd7
      nuinfd = -(winf(itu1)**2*tempd7/nuinf)
      uinf2d = turbintensityinf**2*1.5_realtype*winfd(itu1)
      winfd(itu1) = 0.0_8
    else
      uinf2d = 0.0_8
      goto 100
    end if
    muinfd = muinfd + nuinfd/rhoinf
    rhoinfd = rhoinfd - muinf*nuinfd/rhoinf**2
 100 tempd = machcoef**2*gammainf*uinf2d/rhoinf
    machcoefd = machcoefd + pinf*gammainf*2*machcoef*uinf2d/rhoinf
    uinfd = uinfd + veldirfreestream(3)*winfd(ivz)
    veldirfreestreamd(3) = veldirfreestreamd(3) + uinf*winfd(ivz)
    winfd(ivz) = 0.0_8
    uinfd = uinfd + veldirfreestream(2)*winfd(ivy)
    veldirfreestreamd(2) = veldirfreestreamd(2) + uinf*winfd(ivy)
    winfd(ivy) = 0.0_8
    uinfd = uinfd + veldirfreestream(1)*winfd(ivx)
    veldirfreestreamd(1) = veldirfreestreamd(1) + uinf*winfd(ivx)
    winfd(ivx) = 0.0_8
    call popreal8(gammainf)
    muinfdimd = muinfd/muref
    murefd = murefd - muinfdim*muinfd/muref**2
    tempd1 = rgasdim*rgasd/pref
    trefd = trefd + rhoref*tempd1
    temp0 = gammainf*pinf/rhoinf
    temp = sqrt(temp0)
    if (temp0 .eq. 0.0_8) then
      tempd0 = 0.0
    else
      tempd0 = gammainf*mach*uinfd/(2.0*temp*rhoinf)
    end if
    pinfd = pinfd + tempd0 + tempd
    rhoinfd = rhoinfd + winfd(irho) - pinf*tempd0/rhoinf - pinf*tempd/&
&     rhoinf
    machd = machd + temp*uinfd
    if (rhoref/pref .eq. 0.0_8) then
      tempd3 = 0.0
    else
      tempd3 = timerefd/(2.0*sqrt(rhoref/pref)*pref)
    end if
    if (pref*rhoref .eq. 0.0_8) then
      tempd2 = 0.0
    else
      tempd2 = murefd/(2.0*sqrt(pref*rhoref))
    end if
    rhorefd = rhorefd + pref*tempd2 - rhoinfdim*rhoinfd/rhoref**2 + &
&     tempd3 + tref*tempd1
    prefd = prefd + rhoref*tempd2 - pinfdim*pinfd/pref**2 - rhoref*&
&     tempd3/pref - rhoref*tref*tempd1/pref
    rhoinfdimd = rhoinfdimd + rhorefd + rhoinfd/rhoref
    pinfdimd = pinfdimd + prefd + pinfd/pref
    tempd4 = musuthdim*(tsuthdim+ssuthdim)*muinfdimd/(ssuthdim+tinfdim)
    tinfdimd = tinfdimd + (1.5_realtype*(tinfdim/tsuthdim)**0.5/tsuthdim&
&     -(tinfdim/tsuthdim)**1.5_realtype/(ssuthdim+tinfdim))*tempd4 + &
&     trefd
    pinfd = 0.0_8
    timerefd = 0.0_8
    rhoinfd = 0.0_8
    murefd = 0.0_8
    trefd = 0.0_8
    winfd = 0.0_8
    muinfd = 0.0_8
    uinfd = 0.0_8
    pinfcorrd = 0.0_8
    rgasd = 0.0_8
    prefd = 0.0_8
    rhorefd = 0.0_8
  end subroutine referencestate_b
  subroutine referencestate()
!
!       the original version has been nuked since the computations are
!       no longer necessary when calling from python
!       this is the most compliclated routine in all of adflow. it is
!       stupidly complicated. this is most likely the reason your
!       derivatives are wrong. you don't understand this routine
!       and its effects.
!       this routine *requries* the following as input:
!       mach, pinfdim, tinfdim, rhoinfdim, rgasdim (machcoef non-sa
!        turbulence only)
!       optionally, pref, rhoref and tref are used if they are
!       are non-negative. this only happens when you want the equations
!       normalized by values other than the freestream
!      * this routine computes as output:
!      *   muinfdim, (unused anywhere in code)
!         pref, rhoref, tref, muref, timeref ('dimensional' reference)
!         pinf, pinfcorr, rhoinf, uinf, rgas, muinf, gammainf and winf
!         (non-dimensionalized values used in actual computations)
!
    use constants
    use paramturb
    use inputphysics, only : equations, mach, machcoef, musuthdim, &
&   tsuthdim, veldirfreestream, rgasdim, ssuthdim, eddyvisinfratio, &
&   turbmodel, turbintensityinf
    use flowvarrefstate, only : pinfdim, tinfdim, rhoinfdim, muinfdim,&
&   pref, rhoref, tref, muref, timeref, uref, href, pinf, pinfcorr, &
&   rhoinf, uinf, rgas, muinf, gammainf, winf, nw, nwf, kpresent, winf
    use flowutils_b, only : computegamma, etot
    use turbutils_b, only : sanuknowneddyratio
    implicit none
    integer(kind=inttype) :: sps, nn, mm, ierr
    real(kind=realtype) :: gm1, ratio
    real(kind=realtype) :: nuinf, ktmp, uinf2
    real(kind=realtype) :: vinf, zinf, tmp1(1), tmp2(1)
    intrinsic sqrt
! compute the dimensional viscosity from sutherland's law
    muinfdim = musuthdim*((tsuthdim+ssuthdim)/(tinfdim+ssuthdim))*(&
&     tinfdim/tsuthdim)**1.5_realtype
! set the reference values. they *could* be different from the
! free-stream values for an internal flow simulation. for now,
! we just use the actual free stream values.
    pref = pinfdim
    tref = tinfdim
    rhoref = rhoinfdim
! compute the value of muref, such that the nondimensional
! equations are identical to the dimensional ones.
! note that in the non-dimensionalization of muref there is
! a reference length. however this reference length is 1.0
! in this code, because the coordinates are converted to
! meters.
    muref = sqrt(pref*rhoref)
! compute timeref for a correct nondimensionalization of the
! unsteady equations. some story as for the reference viscosity
! concerning the reference length.
    timeref = sqrt(rhoref/pref)
    href = pref/rhoref
    uref = sqrt(href)
! compute the nondimensional pressure, density, velocity,
! viscosity and gas constant.
    pinf = pinfdim/pref
    rhoinf = rhoinfdim/rhoref
    uinf = mach*sqrt(gammainf*pinf/rhoinf)
    rgas = rgasdim*rhoref*tref/pref
    muinf = muinfdim/muref
    tmp1(1) = tinfdim
    call computegamma(tmp1, tmp2, 1)
    gammainf = tmp2(1)
! ----------------------------------------
!      compute the final winf
! ----------------------------------------
! allocate the memory for winf if necessary
! zero out the winf first
    winf(:) = zero
! set the reference value of the flow variables, except the total
! energy. this will be computed at the end of this routine.
    winf(irho) = rhoinf
    winf(ivx) = uinf*veldirfreestream(1)
    winf(ivy) = uinf*veldirfreestream(2)
    winf(ivz) = uinf*veldirfreestream(3)
! compute the velocity squared based on machcoef. this gives a
! better indication of the 'speed' of the flow so the turubulence
! intensity ration is more meaningful especially for moving
! geometries. (not used in sa model)
    uinf2 = machcoef*machcoef*gammainf*pinf/rhoinf
! set the turbulent variables if transport variables are to be
! solved. we should be checking for rans equations here,
! however, this code is included in block res. the issue is
! that for frozen turbulence (or ank jacobian) we call the
! block_res with equationtype set to laminar even though we are
! actually solving the rans equations. the issue is that, the
! freestream turb variables will be changed to zero, thus
! changing the solution. insteady we check if nw > nwf which
! will accomplish the same thing.
    if (nw .gt. nwf) then
      nuinf = muinf/rhoinf
      select case  (turbmodel) 
      case (spalartallmaras, spalartallmarasedwards) 
        winf(itu1) = sanuknowneddyratio(eddyvisinfratio, nuinf)
      case (komegawilcox, komegamodified, mentersst) 
!=============================================================
        winf(itu1) = 1.5_realtype*uinf2*turbintensityinf**2
        winf(itu2) = winf(itu1)/(eddyvisinfratio*nuinf)
      case (ktau) 
!=============================================================
        winf(itu1) = 1.5_realtype*uinf2*turbintensityinf**2
        winf(itu2) = eddyvisinfratio*nuinf/winf(itu1)
      case (v2f) 
!=============================================================
        winf(itu1) = 1.5_realtype*uinf2*turbintensityinf**2
        winf(itu2) = 0.09_realtype*winf(itu1)**2/(eddyvisinfratio*nuinf)
        winf(itu3) = 0.666666_realtype*winf(itu1)
        winf(itu4) = 0.0_realtype
      end select
    end if
! set the value of pinfcorr. in case a k-equation is present
! add 2/3 times rho*k.
    pinfcorr = pinf
    if (kpresent) pinfcorr = pinf + two*third*rhoinf*winf(itu1)
! compute the free stream total energy.
    ktmp = zero
    if (kpresent) ktmp = winf(itu1)
    vinf = zero
    zinf = zero
    call etot(rhoinf, uinf, vinf, zinf, pinfcorr, ktmp, winf(irhoe), &
&       kpresent)
  end subroutine referencestate
end module initializeflow_b
