!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of getcostfunction2 in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: funcvalues
!   with respect to varying inputs: gammainf pinf rhoinfdim pinfdim
!                pref machgrid lengthref machcoef dragdirection
!                liftdirection pointref moment sepsensoravg force
!                cavitation sepsensor
subroutine getcostfunction2_b(force, forced, moment, momentd, sepsensor&
& , sepsensord, sepsensoravg, sepsensoravgd, cavitation, cavitationd, &
& alpha, beta, liftindex)
! compute the value of the actual objective function based on the
! (summed) forces and moments and any other "extra" design
! variables. the index of the objective is determined by 'idv'. this
! function is intended to be ad'ed in reverse mode. 
  use constants
  use inputtimespectral
  use costfunctions
  use inputphysics
  use flowvarrefstate
  use inputtsstabderiv
  implicit none
! input 
  integer(kind=inttype), intent(in) :: liftindex
  real(kind=realtype), dimension(3, ntimeintervalsspectral), intent(in) &
& :: force, moment
  real(kind=realtype), dimension(3, ntimeintervalsspectral) :: forced, &
& momentd
  real(kind=realtype), intent(in) :: sepsensor, cavitation, sepsensoravg&
& (3)
  real(kind=realtype) :: sepsensord, cavitationd, sepsensoravgd(3)
  real(kind=realtype), intent(in) :: alpha, beta
! working
  real(kind=realtype) :: fact, factmoment, scaledim, ovrnts
  real(kind=realtype) :: factd, factmomentd, scaledimd
  real(kind=realtype), dimension(3) :: cf, cm
  real(kind=realtype), dimension(3) :: cfd, cmd
  real(kind=realtype) :: elasticmomentx, elasticmomenty, elasticmomentz
  real(kind=realtype), dimension(ntimeintervalsspectral, 8) :: basecoef
  real(kind=realtype), dimension(8) :: coef0, dcdalpha, dcdalphadot, &
& dcdq, dcdqdot
  real(kind=realtype), dimension(8) :: coef0d, dcdalphad, dcdalphadotd
  real(kind=realtype) :: bendingmoment
  real(kind=realtype) :: bendingmomentd
  integer(kind=inttype) :: sps
  real(kind=realtype) :: tmp
  real(kind=realtype) :: tmp0
  real(kind=realtype) :: tmp1
  real(kind=realtype) :: tmp2
  real(kind=realtype) :: tmp3
  real(kind=realtype) :: tmp4
  real(kind=realtype) :: tmp5
  real(kind=realtype) :: tmp6
  real(kind=realtype) :: tmp7
  real(kind=realtype) :: tmp8
  integer :: branch
  real(kind=realtype) :: temp1
  real(kind=realtype) :: temp0
  real(kind=realtype) :: tmpd
  real(kind=realtype) :: tempd
  real(kind=realtype) :: tmpd8
  real(kind=realtype) :: tmpd7
  real(kind=realtype) :: tempd1
  real(kind=realtype) :: tmpd6
  real(kind=realtype) :: tempd0
  real(kind=realtype) :: tmpd5
  real(kind=realtype) :: tmpd4
  real(kind=realtype) :: tmpd3
  real(kind=realtype) :: tmpd2
  real(kind=realtype) :: tmpd1
  real(kind=realtype) :: tmpd0
  real(kind=realtype) :: temp
! generate constants
  scaledim = pref/pinf
  fact = two/(gammainf*pinf*machcoef**2*surfaceref*lref**2*scaledim)
  factmoment = fact/(lengthref*lref)
  ovrnts = one/ntimeintervalsspectral
! pre-compute ts stability info if required:
  if (tsstability) then
    call pushinteger4(liftindex)
    call computetsderivatives(force, moment, liftindex, coef0, &
&                          dcdalpha, dcdalphadot, dcdq, dcdqdot)
    call pushcontrol1b(0)
  else
    call pushcontrol1b(1)
  end if
  funcvalues = zero
! now we just compute each cost function:
  do sps=1,ntimeintervalsspectral
    funcvalues(costfuncforcex) = funcvalues(costfuncforcex) + ovrnts*&
&     force(1, sps)
    funcvalues(costfuncforcey) = funcvalues(costfuncforcey) + ovrnts*&
&     force(2, sps)
    funcvalues(costfuncforcez) = funcvalues(costfuncforcez) + ovrnts*&
&     force(3, sps)
    funcvalues(costfuncmomx) = funcvalues(costfuncmomx) + ovrnts*moment(&
&     1, sps)
    funcvalues(costfuncmomy) = funcvalues(costfuncmomy) + ovrnts*moment(&
&     2, sps)
    funcvalues(costfuncmomz) = funcvalues(costfuncmomz) + ovrnts*moment(&
&     3, sps)
    funcvalues(costfuncsepsensor) = funcvalues(costfuncsepsensor) + &
&     ovrnts*sepsensor
    funcvalues(costfunccavitation) = funcvalues(costfunccavitation) + &
&     ovrnts*cavitation
    funcvalues(costfuncsepsensoravgx) = funcvalues(costfuncsepsensoravgx&
&     ) + ovrnts*sepsensoravg(1)
    funcvalues(costfuncsepsensoravgy) = funcvalues(costfuncsepsensoravgy&
&     ) + ovrnts*sepsensoravg(2)
    funcvalues(costfuncsepsensoravgz) = funcvalues(costfuncsepsensoravgz&
&     ) + ovrnts*sepsensoravg(3)
! bending moment calc
    cm = factmoment*moment(:, sps)
    cf = fact*force(:, sps)
    call computerootbendingmoment(cf, cm, liftindex, bendingmoment)
    funcvalues(costfuncbendingcoef) = funcvalues(costfuncbendingcoef) + &
&     ovrnts*bendingmoment
  end do
  tmp = funcvalues(costfuncforcex)*fact
  call pushreal8(funcvalues(costfuncforcexcoef))
  funcvalues(costfuncforcexcoef) = tmp
  tmp0 = funcvalues(costfuncforcey)*fact
  call pushreal8(funcvalues(costfuncforceycoef))
  funcvalues(costfuncforceycoef) = tmp0
  tmp1 = funcvalues(costfuncforcez)*fact
  call pushreal8(funcvalues(costfuncforcezcoef))
  funcvalues(costfuncforcezcoef) = tmp1
  tmp2 = funcvalues(costfuncmomx)*factmoment
  call pushreal8(funcvalues(costfuncmomxcoef))
  funcvalues(costfuncmomxcoef) = tmp2
  tmp3 = funcvalues(costfuncmomy)*factmoment
  call pushreal8(funcvalues(costfuncmomycoef))
  funcvalues(costfuncmomycoef) = tmp3
  tmp4 = funcvalues(costfuncmomz)*factmoment
  call pushreal8(funcvalues(costfuncmomzcoef))
  funcvalues(costfuncmomzcoef) = tmp4
  tmp5 = funcvalues(costfuncforcex)*liftdirection(1) + funcvalues(&
&   costfuncforcey)*liftdirection(2) + funcvalues(costfuncforcez)*&
&   liftdirection(3)
  call pushreal8(funcvalues(costfunclift))
  funcvalues(costfunclift) = tmp5
  tmp6 = funcvalues(costfuncforcex)*dragdirection(1) + funcvalues(&
&   costfuncforcey)*dragdirection(2) + funcvalues(costfuncforcez)*&
&   dragdirection(3)
  call pushreal8(funcvalues(costfuncdrag))
  funcvalues(costfuncdrag) = tmp6
  tmp7 = funcvalues(costfunclift)*fact
  call pushreal8(funcvalues(costfuncliftcoef))
  funcvalues(costfuncliftcoef) = tmp7
! -------------------- time spectral objectives ------------------
  funcvaluesd(costfunccmzqdot) = 0.0_8
  funcvaluesd(costfunccdqdot) = 0.0_8
  funcvaluesd(costfuncclqdot) = 0.0_8
  funcvaluesd(costfunccmzq) = 0.0_8
  funcvaluesd(costfunccdq) = 0.0_8
  funcvaluesd(costfuncclq) = 0.0_8
  dcdalphadotd = 0.0_8
  dcdalphadotd(8) = dcdalphadotd(8) + funcvaluesd(costfunccmzalphadot)
  funcvaluesd(costfunccmzalphadot) = 0.0_8
  dcdalphadotd(2) = dcdalphadotd(2) + funcvaluesd(costfunccdalphadot)
  funcvaluesd(costfunccdalphadot) = 0.0_8
  dcdalphadotd(1) = dcdalphadotd(1) + funcvaluesd(costfuncclalphadot)
  funcvaluesd(costfuncclalphadot) = 0.0_8
  dcdalphad = 0.0_8
  dcdalphad(8) = dcdalphad(8) + funcvaluesd(costfunccmzalpha)
  funcvaluesd(costfunccmzalpha) = 0.0_8
  dcdalphad(2) = dcdalphad(2) + funcvaluesd(costfunccdalpha)
  funcvaluesd(costfunccdalpha) = 0.0_8
  dcdalphad(1) = dcdalphad(1) + funcvaluesd(costfuncclalpha)
  funcvaluesd(costfuncclalpha) = 0.0_8
  coef0d = 0.0_8
  coef0d(8) = coef0d(8) + funcvaluesd(costfunccm0)
  funcvaluesd(costfunccm0) = 0.0_8
  coef0d(2) = coef0d(2) + funcvaluesd(costfunccd0)
  funcvaluesd(costfunccd0) = 0.0_8
  coef0d(1) = coef0d(1) + funcvaluesd(costfunccl0)
  funcvaluesd(costfunccl0) = 0.0_8
  tmpd = funcvaluesd(costfuncdragcoef)
  funcvaluesd(costfuncdragcoef) = 0.0_8
  funcvaluesd(costfuncdrag) = funcvaluesd(costfuncdrag) + fact*tmpd
  factd = funcvalues(costfuncdrag)*tmpd
  call popreal8(funcvalues(costfuncliftcoef))
  tmpd0 = funcvaluesd(costfuncliftcoef)
  funcvaluesd(costfuncliftcoef) = 0.0_8
  funcvaluesd(costfunclift) = funcvaluesd(costfunclift) + fact*tmpd0
  factd = factd + funcvalues(costfunclift)*tmpd0
  dragdirectiond = 0.0_8
  call popreal8(funcvalues(costfuncdrag))
  tmpd1 = funcvaluesd(costfuncdrag)
  funcvaluesd(costfuncdrag) = 0.0_8
  dragdirectiond = 0.0_8
  funcvaluesd(costfuncforcex) = funcvaluesd(costfuncforcex) + &
&   dragdirection(1)*tmpd1
  dragdirectiond(1) = dragdirectiond(1) + funcvalues(costfuncforcex)*&
&   tmpd1
  funcvaluesd(costfuncforcey) = funcvaluesd(costfuncforcey) + &
&   dragdirection(2)*tmpd1
  dragdirectiond(2) = dragdirectiond(2) + funcvalues(costfuncforcey)*&
&   tmpd1
  funcvaluesd(costfuncforcez) = funcvaluesd(costfuncforcez) + &
&   dragdirection(3)*tmpd1
  dragdirectiond(3) = dragdirectiond(3) + funcvalues(costfuncforcez)*&
&   tmpd1
  liftdirectiond = 0.0_8
  call popreal8(funcvalues(costfunclift))
  tmpd2 = funcvaluesd(costfunclift)
  funcvaluesd(costfunclift) = 0.0_8
  liftdirectiond = 0.0_8
  funcvaluesd(costfuncforcex) = funcvaluesd(costfuncforcex) + &
&   liftdirection(1)*tmpd2
  liftdirectiond(1) = liftdirectiond(1) + funcvalues(costfuncforcex)*&
&   tmpd2
  funcvaluesd(costfuncforcey) = funcvaluesd(costfuncforcey) + &
&   liftdirection(2)*tmpd2
  liftdirectiond(2) = liftdirectiond(2) + funcvalues(costfuncforcey)*&
&   tmpd2
  funcvaluesd(costfuncforcez) = funcvaluesd(costfuncforcez) + &
&   liftdirection(3)*tmpd2
  liftdirectiond(3) = liftdirectiond(3) + funcvalues(costfuncforcez)*&
&   tmpd2
  call popreal8(funcvalues(costfuncmomzcoef))
  tmpd3 = funcvaluesd(costfuncmomzcoef)
  funcvaluesd(costfuncmomzcoef) = 0.0_8
  funcvaluesd(costfuncmomz) = funcvaluesd(costfuncmomz) + factmoment*&
&   tmpd3
  factmomentd = funcvalues(costfuncmomz)*tmpd3
  call popreal8(funcvalues(costfuncmomycoef))
  tmpd4 = funcvaluesd(costfuncmomycoef)
  funcvaluesd(costfuncmomycoef) = 0.0_8
  funcvaluesd(costfuncmomy) = funcvaluesd(costfuncmomy) + factmoment*&
&   tmpd4
  factmomentd = factmomentd + funcvalues(costfuncmomy)*tmpd4
  call popreal8(funcvalues(costfuncmomxcoef))
  tmpd5 = funcvaluesd(costfuncmomxcoef)
  funcvaluesd(costfuncmomxcoef) = 0.0_8
  funcvaluesd(costfuncmomx) = funcvaluesd(costfuncmomx) + factmoment*&
&   tmpd5
  factmomentd = factmomentd + funcvalues(costfuncmomx)*tmpd5
  call popreal8(funcvalues(costfuncforcezcoef))
  tmpd6 = funcvaluesd(costfuncforcezcoef)
  funcvaluesd(costfuncforcezcoef) = 0.0_8
  funcvaluesd(costfuncforcez) = funcvaluesd(costfuncforcez) + fact*tmpd6
  factd = factd + funcvalues(costfuncforcez)*tmpd6
  call popreal8(funcvalues(costfuncforceycoef))
  tmpd7 = funcvaluesd(costfuncforceycoef)
  funcvaluesd(costfuncforceycoef) = 0.0_8
  funcvaluesd(costfuncforcey) = funcvaluesd(costfuncforcey) + fact*tmpd7
  factd = factd + funcvalues(costfuncforcey)*tmpd7
  call popreal8(funcvalues(costfuncforcexcoef))
  tmpd8 = funcvaluesd(costfuncforcexcoef)
  funcvaluesd(costfuncforcexcoef) = 0.0_8
  funcvaluesd(costfuncforcex) = funcvaluesd(costfuncforcex) + fact*tmpd8
  factd = factd + funcvalues(costfuncforcex)*tmpd8
  lengthrefd = 0.0_8
  pointrefd = 0.0_8
  momentd = 0.0_8
  sepsensoravgd = 0.0_8
  forced = 0.0_8
  cavitationd = 0.0_8
  sepsensord = 0.0_8
  do sps=ntimeintervalsspectral,1,-1
    bendingmomentd = ovrnts*funcvaluesd(costfuncbendingcoef)
    cf = fact*force(:, sps)
    cm = factmoment*moment(:, sps)
    call computerootbendingmoment_b(cf, cfd, cm, cmd, liftindex, &
&                             bendingmoment, bendingmomentd)
    factd = factd + sum(force(:, sps)*cfd)
    forced(:, sps) = forced(:, sps) + fact*cfd
    factmomentd = factmomentd + sum(moment(:, sps)*cmd)
    momentd(:, sps) = momentd(:, sps) + factmoment*cmd
    sepsensoravgd(3) = sepsensoravgd(3) + ovrnts*funcvaluesd(&
&     costfuncsepsensoravgz)
    sepsensoravgd(2) = sepsensoravgd(2) + ovrnts*funcvaluesd(&
&     costfuncsepsensoravgy)
    sepsensoravgd(1) = sepsensoravgd(1) + ovrnts*funcvaluesd(&
&     costfuncsepsensoravgx)
    cavitationd = cavitationd + ovrnts*funcvaluesd(costfunccavitation)
    sepsensord = sepsensord + ovrnts*funcvaluesd(costfuncsepsensor)
    momentd(3, sps) = momentd(3, sps) + ovrnts*funcvaluesd(costfuncmomz)
    momentd(2, sps) = momentd(2, sps) + ovrnts*funcvaluesd(costfuncmomy)
    momentd(1, sps) = momentd(1, sps) + ovrnts*funcvaluesd(costfuncmomx)
    forced(3, sps) = forced(3, sps) + ovrnts*funcvaluesd(costfuncforcez)
    forced(2, sps) = forced(2, sps) + ovrnts*funcvaluesd(costfuncforcey)
    forced(1, sps) = forced(1, sps) + ovrnts*funcvaluesd(costfuncforcex)
  end do
  call popcontrol1b(branch)
  if (branch .eq. 0) then
    call popinteger4(liftindex)
    call computetsderivatives_b(force, forced, moment, momentd, &
&                         liftindex, coef0, coef0d, dcdalpha, dcdalphad&
&                         , dcdalphadot, dcdalphadotd, dcdq, dcdqdot)
  else
    gammainfd = 0.0_8
    pinfd = 0.0_8
    rhoinfdimd = 0.0_8
    pinfdimd = 0.0_8
    prefd = 0.0_8
    machgridd = 0.0_8
    machcoefd = 0.0_8
  end if
  tempd = factmomentd/(lref*lengthref)
  factd = factd + tempd
  lengthrefd = lengthrefd - fact*tempd/lengthref
  temp1 = machcoef**2*scaledim
  temp0 = surfaceref*lref**2
  temp = temp0*gammainf*pinf
  tempd0 = -(two*factd/(temp**2*temp1**2))
  tempd1 = temp1*temp0*tempd0
  gammainfd = gammainfd + pinf*tempd1
  machcoefd = machcoefd + scaledim*temp*2*machcoef*tempd0
  scaledimd = temp*machcoef**2*tempd0
  pinfd = pinfd + gammainf*tempd1 - pref*scaledimd/pinf**2
  prefd = prefd + scaledimd/pinf
end subroutine getcostfunction2_b
