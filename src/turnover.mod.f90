module md_turnover
  !////////////////////////////////////////////////////////////////
  ! NPP_LPJ MODULE
  ! Contains the "main" subroutine 'npp' and all necessary 
  ! subroutines for handling input/output. 
  ! Every module that implements 'npp' must contain this list 
  ! of subroutines (names that way).
  !   - npp
  !   - getpar_modl_npp
  !   - initio_npp
  !   - initoutput_npp
  !   - getout_daily_npp
  !   - getout_monthly_npp
  !   - writeout_ascii_npp
  ! Required module-independent model state variables (necessarily 
  ! updated by 'waterbal') are:
  !   - daily NPP ('dnpp')
  !   - soil temperature ('xxx')
  !   - inorganic N _pools ('no3', 'nh4')
  !   - xxx 
  ! Copyright (C) 2015, see LICENSE, Benjamin David Stocker
  ! contact: b.stocker@imperial.ac.uk
  !----------------------------------------------------------------
  use md_classdefs
  use md_plant
    
  implicit none

  private
  public turnover, turnover_root, turnover_leaf, turnover_labl

contains

  subroutine turnover( jpngr, doy )
    !////////////////////////////////////////////////////////////////
    !  Annual vegetation biomass turnover, called at the end of the
    !  year.
    !----------------------------------------------------------------
    use md_classdefs
    use md_params_core, only: npft, eps
    use md_phenology, only: shedleaves

    ! arguments
    integer, intent(in) :: jpngr
    integer, intent(in) :: doy

    ! local variables
    integer :: pft
    integer :: lu
    real :: dlabl
    real :: dleaf
    real :: droot

    ! xxx verbose
    logical, parameter :: verbose = .false.
    type( orgpool ) :: orgtmp, orgtmp2

    do pft=1,npft

      if (plabl(pft,jpngr)%c%c12 < -1.0*eps) stop 'before turnover labile C is neg.'
      if (plabl(pft,jpngr)%n%n14 < -1.0*eps) stop 'before turnover labile N is neg.'

      !--------------------------------------------------------------
      ! Get turnover fractions
      ! Turnover-rates are reciprocals of tissue longevity
      ! dleaf=1.0/long_leaf(pft)
      ! assuming no continuous leaf turnover
      !--------------------------------------------------------------
      if (params_pft_plant(pft)%grass) then

        if (shedleaves(doy,pft)) then

          droot = 1.0
          dleaf = 1.0
          dlabl = 1.0

          stop 'shedding the fucking leaves'
          
        else

          ! Increase turnover rate towards high LAI ( when using non-zero value for k_decay_leaf_width, e.g. 0.08 )
          dleaf =  (lai_ind(pft,jpngr)*params_pft_plant(pft)%k_decay_leaf_width)**8 + params_pft_plant(pft)%k_decay_leaf_base

          ! constant turnover rate
          droot = params_pft_plant(pft)%k_decay_root
          dlabl = params_pft_plant(pft)%k_decay_labl

        end if

      else

        stop 'turnover not implemented for non-grasses'

      endif

      !--------------------------------------------------------------
      ! Calculate leaf turnover in this day 
      !--------------------------------------------------------------
      if (verbose) print*, 'calling turnover_leaf() ... '
      if (verbose) print*, '              with state variables:'
      if (verbose) print*, '              pleaf = ', pleaf(:,jpngr)
      if (verbose) print*, '              plitt = ', plitt_af(pft,jpngr)
      if (verbose) orgtmp  =  pleaf(pft,jpngr)
      if (verbose) orgtmp2 =  plitt_af(pft,jpngr)
      !--------------------------------------------------------------
      if ( dleaf>0.0 )                 call turnover_leaf( dleaf, pft, jpngr )
      !--------------------------------------------------------------
      if (verbose) print*, '              ==> returned: '
      if (verbose) print*, '              pleaf = ', pleaf(:,jpngr)
      if (verbose) print*, '              plitt = ', plitt_af(pft,jpngr)
      if (verbose) print*, '              --- balance: '
      if (verbose) print*, '                  dlitt - dleaf                = ',  orgminus( &
                                                                                    orgminus( &
                                                                                      plitt_af(pft,jpngr), &
                                                                                      orgtmp2 &
                                                                                      ), &
                                                                                    orgminus( &
                                                                                      orgtmp, &
                                                                                      pleaf(pft,jpngr) &
                                                                                      ) &
                                                                                    )

      !--------------------------------------------------------------
      ! Calculate root turnover in this day 
      !--------------------------------------------------------------
      if (verbose) print*, 'calling turnover_root() ... '
      if (verbose) print*, '              with state variables:'
      if (verbose) print*, '              pleaf = ', proot(:,jpngr)
      if (verbose) print*, '              plitt = ', plitt_bg(pft,jpngr)
      if (verbose) orgtmp  =  proot(pft,jpngr)
      if (verbose) orgtmp2 =  plitt_bg(pft,jpngr)
      !--------------------------------------------------------------
      if ( droot>0.0 )                 call turnover_root( droot, pft, jpngr )
      !--------------------------------------------------------------
      if (verbose) print*, '              ==> returned: '
      if (verbose) print*, '              proot = ', proot(:,jpngr)
      if (verbose) print*, '              plitt = ', plitt_bg(pft,jpngr)
      if (verbose) print*, '              --- balance: '
      if (verbose) print*, '                  dlitt - droot                = ',  orgminus( &
                                                                                    orgminus( &
                                                                                      plitt_bg(pft,jpngr), &
                                                                                      orgtmp2 &
                                                                                      ), &
                                                                                    orgminus( &
                                                                                      orgtmp, &
                                                                                      proot(pft,jpngr) &
                                                                                      ) &
                                                                                    )

      !--------------------------------------------------------------
      ! Calculate labile turnover in this day 
      !--------------------------------------------------------------
      if (verbose) print*, 'calling turnover_root() ... '
      if (verbose) print*, '              with state variables:'
      if (verbose) print*, '              pleaf = ', plabl(:,jpngr)
      if (verbose) print*, '              plitt = ', plitt_af(pft,jpngr)
      if (verbose) orgtmp  =  plabl(pft,jpngr)
      if (verbose) orgtmp2 =  plitt_af(pft,jpngr)
      !--------------------------------------------------------------
      if ( dlabl>0.0 )                 call turnover_labl( dlabl, pft, jpngr )
      !--------------------------------------------------------------
      if (verbose) print*, '              ==> returned: '
      if (verbose) print*, '              plabl = ', plabl(:,jpngr)
      if (verbose) print*, '              plitt = ', plitt_af(pft,jpngr)
      if (verbose) print*, '              --- balance: '
      if (verbose) print*, '                  dlitt - dlabl                = ',  orgminus( &
                                                                                    orgminus( &
                                                                                      plitt_af(pft,jpngr), &
                                                                                      orgtmp2 &
                                                                                      ), &
                                                                                    orgminus( &
                                                                                      orgtmp, &
                                                                                      proot(pft,jpngr) &
                                                                                      ) &
                                                                                    )
    enddo                     !pft

  end subroutine turnover


  subroutine turnover_leaf( dleaf, pft, jpngr )
    !//////////////////////////////////////////////////////////////////
    ! Execute turnover of fraction dleaf for leaf pool
    !------------------------------------------------------------------
    use md_params_core, only: eps
    use md_waterbal, only: solar
    use md_gpp, only: out_pmodel

    ! arguments
    real, intent(in)    :: dleaf
    integer, intent(in) :: pft
    integer, intent(in) :: jpngr

    ! local variables
    type(orgpool) :: lm_turn
    type(orgpool) :: lm_init

    real :: nleaf
    real :: cleaf
    real :: dlai
    real :: lai_new
    real :: diff
    integer :: nitr

    ! number of iterations to match leaf C given leaf N
    nitr = 0

    ! store leaf C and N before turnover
    lm_init = pleaf(pft,jpngr)

    ! reduce leaf C (given by turnover rate)
    cleaf = ( 1.0 - dleaf ) *  pleaf(pft,jpngr)%c%c12

    ! get new LAI based on cleaf
    lai_new = get_lai( pft, cleaf, solar%meanmppfd(:), out_pmodel(pft,:)%actnv_unitiabs )

    ! update canopy state (only variable fAPAR so far implemented)
    canopy(pft) = get_canopy( lai_new )

    ! re-calculate metabolic and structural N, given new LAI and fAPAR
    leaftraits(pft) = get_leaftraits( pft, lai_new, solar%meanmppfd(:), out_pmodel(pft,:)%actnv_unitiabs )

    ! get updated leaf N
    nleaf = leaftraits(pft)%narea_canopy

    do while ( nleaf > lm_init%n%n14 )

      nitr = nitr + 1

      ! reduce leaf C a bit more
      cleaf = cleaf * lm_init%n%n14 / nleaf

      ! get new LAI based on cleaf
      lai_new = get_lai( pft, cleaf, solar%meanmppfd(:), out_pmodel(pft,:)%actnv_unitiabs )

      ! update canopy state (only variable fAPAR so far implemented)
      canopy(pft) = get_canopy( lai_new )

      ! re-calculate metabolic and structural N, given new LAI and fAPAR
      leaftraits(pft) = get_leaftraits( pft, lai_new, solar%meanmppfd(:), out_pmodel(pft,:)%actnv_unitiabs )

      ! get updated leaf N
      nleaf = leaftraits(pft)%narea_canopy

      if (nitr>30) exit

    end do

    if (nitr>0) print*,'no. of iterations ', nitr
    if (nitr>0) print*,'final reduction of leaf C ', cleaf / lm_init%c%c12
    if (nitr>0) print*,'final reduction of leaf N ', nleaf / lm_init%n%n14

    ! update 
    lai_ind(pft,jpngr) = lai_new
    pleaf(pft,jpngr)%c%c12 = cleaf
    pleaf(pft,jpngr)%n%n14 = nleaf

    ! determine C and N turned over
    lm_turn = orgminus( lm_init, pleaf(pft,jpngr) )

    if ( lm_turn%c%c12 < -1.0*eps ) then
      stop 'negative turnover C'
    else if ( lm_turn%c%c12 < 0.0 ) then
       lm_turn%c%c12 = 0.0
    end if
    if ( lm_turn%n%n14 < -1.0*eps ) then
      stop 'negative turnover N'
    else if ( lm_turn%n%n14 < 0.0 ) then
       lm_turn%n%n14 = 0.0
    end if

    ! add all organic (fixed) C to litter
    call cmvRec( lm_turn%c, lm_turn%c, plitt_af(pft,jpngr)%c, outaCveg2lit(pft,jpngr), scale=nind(pft,jpngr))
    ! call cmv( lm_turn%c, lm_turn%c, plitt_af(pft,jpngr)%c, scale=nind(pft,jpngr) )

    ! retain fraction of N
    call nmv( nfrac( params_plant%f_nretain, lm_turn%n ), lm_turn%n, plabl(pft,jpngr)%n )

    ! rest goes to litter
    call nmvRec( lm_turn%n, lm_turn%n, plitt_af(pft,jpngr)%n, outaNveg2lit(pft,jpngr), scale=nind(pft,jpngr) )
    ! call nmv( lm_turn%n, lm_turn%n, plitt_af(pft,jpngr)%n, scale=nind(pft,jpngr) )

  end subroutine turnover_leaf


  subroutine turnover_root( droot, pft, jpngr )
    !//////////////////////////////////////////////////////////////////
    ! Execute turnover of fraction droot for root pool
    !------------------------------------------------------------------
    ! arguments
    real, intent(in)    :: droot
    integer, intent(in) :: pft
    integer, intent(in) :: jpngr

    ! local variables
    type(orgpool) :: rm_turn

    ! determine absolute turnover
    rm_turn = orgfrac( droot, proot(pft,jpngr) ) ! root turnover

    ! reduce leaf mass and root mass
    call orgsub( rm_turn, proot(pft,jpngr) )

    ! add all organic (fixed) C to litter
    call cmvRec( rm_turn%c, rm_turn%c, plitt_bg(pft,jpngr)%c, outaCveg2lit(pft,jpngr), scale=nind(pft,jpngr))
    ! call cmv( rm_turn%c, rm_turn%c, plitt_bg(pft,jpngr)%c, scale=nind(pft,jpngr))

    ! retain fraction of N
    call nmv( nfrac( params_plant%f_nretain, rm_turn%n ), rm_turn%n, plabl(pft,jpngr)%n )

    ! rest goes to litter
    call nmvRec( rm_turn%n, rm_turn%n, plitt_bg(pft,jpngr)%n, outaNveg2lit(pft,jpngr), scale=nind(pft,jpngr) )
    ! call nmv( rm_turn%n, rm_turn%n, plitt_bg(pft,jpngr)%n, scale=nind(pft,jpngr) )

  end subroutine turnover_root


  subroutine turnover_labl( dlabl, pft, jpngr )
    !//////////////////////////////////////////////////////////////////
    ! Execute turnover of fraction dlabl for labl pool
    !------------------------------------------------------------------
    ! arguments
    real, intent(in)    :: dlabl
    integer, intent(in) :: pft
    integer, intent(in) :: jpngr

    ! local variables
    type(orgpool) :: lb_turn

    ! detelbine absolute turnover
    lb_turn = orgfrac( dlabl, plabl(pft,jpngr) ) ! labl turnover

    !! xxx think of something more plausible to put the labile C and N to

    ! reduce leaf mass and labl mass
    call orgsub( lb_turn, plabl(pft,jpngr) )

    call orgmvRec( lb_turn, lb_turn, plitt_af(pft,jpngr), outaCveg2lit(pft,jpngr), outaNveg2lit(pft,jpngr), scale=nind(pft,jpngr))


  end subroutine turnover_labl


end module md_turnover
