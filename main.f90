      program main
      use parameters
      use init
      use pbc
      use integraforces
      use statvis
      use radial_distribution

      implicit none
      character(len=50) :: input_name
      real*8, allocatable :: pos(:,:), vel(:,:)
      
      real*8 :: time,ekin,epot,Tins,P
      integer :: i,j,flag_g

      ! Per executar el programa cal fer >> main.x input_file. Si no, donara error.
      if (command_argument_count() == 0) stop "ERROR: Cridar fent >> ./main.x input_path"
      call get_command_argument(1, input_name)
      
      ! Obrim input i el llegim
      open(unit=10, file=input_name)
      call get_param(10)
      close(10)

      print*,"------Parameters------"
      print*, "N=",N,"D=",D
      print*,"dt_sim=",dt_sim
      print*,"rho=",rho,"T=",T_ref,"L=",L
      print*,"eps=",epsilon,"sigma=",sigma,"rc=",rc
      print*,"n_meas,n_conf,n_total=",n_meas,n_conf,n_total
      
      ! Allocates
      allocate(pos(D, N))
      allocate(vel(D,N))   

      ! Initialize positions and velocities
      call init_sc(pos)
      call init_vel(vel, 10.d0)  ! Cridem amb temperatura reduida (T'=10) molt alta per fer el melting


      ! Start melting of the system
      open(unit=10,file="results/thermodynamics_initialization.dat") ! AJ: open result for initialitzation.
      open(unit=11,file="results/init_conf.xyz")

      call writeXyz(D,N,pos,11)

      flag_g = 0 ! DM: don't write g(r)
      call vvel_solver(5000,1.d-4,pos,vel,10.d0,10,0,flag_g) ! AJ: Initialization of system.

      call writeXyz(D,N,pos,11) ! AJ: write initial configuration, check that it is random.

      close(10)
      close(11)

      ! Start dynamics
      call init_vel(vel, T_ref) ! AJ: reescale to target temperature


      open(unit=10,file="results/thermodynamics.dat")
      open(unit=11,file="results/trajectory.xyz")
      open(unit=12,file="results/radial_distribution.dat")
      ! Set the variables for computing g(r) (defined in rad_dist module)
      Nshells = 100
      call prepare_shells(Nshells)
      

      do i = 1,n_total
      
            call verlet_v_step(pos,vel,time,dt_sim)
            call andersen_therm(vel,dt_sim,T_ref)

            if(mod(i,n_meas) == 0) then ! AJ : measure every n_meas steps
                  !AJ: TODO
                  !verlet_v_step (Laia) doesnt return epot or P, it should
                  !statistics (Jaume) has to add averages here
                  !g(r) also need to be done.


                  call energy_kin(vel,ekin,Tins)

                  write(10,*) time, ekin, epot, ekin+epot, Tins, sum(vel,2)
                  !We sould also need pressure here.
                  call writeXyz(D,N,pos,11)
                  ! Compute g(r) and write to file
                  call rad_distr_fun(pos,Nshells)
                  do j=1,Nshells
                  	write(12,*) grid_shells*(j-1), g(j)
                  enddo
                  write(12,*) ! separation line
            endif
      enddo

      close(10)
      close(11)

      ! Deallocates
      deallocate(pos) 
      deallocate(vel)

      end program main
