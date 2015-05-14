        program getqiavg

c prints out the res in structure 2 that interact (CA<rcut) with any res in structure 1
c compile on 64 bit node: gfortran -mcmodel=medium getqiavg_ca.f -o getqiavg_ca
        parameter (maxres=10001)
        parameter (maxpdb=3001)

        real prcord(0:maxpdb,maxres,3,6),x,y,z,cordcnt(0:maxpdb,maxres)

        character res_type(2,maxres)*3,atom_type*2,line_type*4,
     *       tres_type*3,res_id(2,maxres)*6,tres_id*6,tempr*6,aa*1,
     *       ccount*10

        integer atom_id,resnum,tgNres(2),ncount

        integer numcrd,numpro,nmdifv,numpdb

        real class(20), rcut,dist(0:1,maxres,maxres,4),del,
     *       width(maxres),qi_cut(maxpdb,maxres),
     *       cntqi_cut(maxpdb,maxres),avg_qi_cut(maxres),
     *       cntavg_qi_cut(maxres)

        character profile(0:maxpdb)*200,chain_id(2,maxres)*2,tchain_id*2

        integer itg,Ntg,id,i,j,ctype,i1,i2,itab

        data class /1.0,1.0,1.0,1.0,5.0,1.0,
     *  1.0,1.0,1.0,5.0,
     *  5.0,1.0,5.0,5.0,
     *  1.0,1.0,1.0,5.0,5.0,5.0/

        data numcrd /3/
        data numpro /1/
        data nmdifv /1/


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc   Begin   cccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c     f77  pdb_2_movieseg.f -o pdb_2_movieseg.out

        open(12,file='targlist',status='old')

        read(12,33) profile(0) !target
        read(12,*) tgNres(1)
        read(12,*) rcut
        read(12,*) numpdb

        do itg=1,numpdb
           read(12,33) profile(itg) !ensemble proteins
        enddo
 33     format(a200)

        close(12)

        if(maxres.lt.tgNres(1).or.maxres.lt.tgNres(1)) then
           write(6,*) 'error getcontacts',tgNres(1),maxres
           stop
        endif
        if(maxpdb.lt.numpdb) then
           write(6,*) 'error getcontacts',numpdb,maxpdb
           stop
        endif


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc  get target coords cccccccccccccccccccccc

        prcord(:,:,1:3,1:5)=9999.9999
        prcord(:,:,1:3,6)=0.0
        cordcnt(:,:)=0.0
        do itg=0,numpdb

         resnum = 0
         tempr=''

        open(19,file=trim(profile(itg)),status='old')

135     read(19,175,end=250) line_type

        if (line_type .eq. 'ATOM') then

        backspace 19

        read(19,200,end=250)atom_id,atom_type,
     *  tres_type,tchain_id,tres_id,x,y,z

        if(tempr.ne.tres_id) then
           tempr=tres_id
           resnum = resnum+1
           res_type(1,resnum)=tres_type
           chain_id(1,resnum)=tchain_id
           res_id(1,resnum)=tres_id
c        write(6,*)resnum,chain_id(1,resnum),
c     *   res_type(1,resnum),res_id(1,resnum),x
        endif

        if(atom_type .eq. 'CA'.or.atom_type .eq. 'P') then
        prcord(itg,resnum,1,1)=x
        prcord(itg,resnum,2,1)=y
        prcord(itg,resnum,3,1)=z
                if (res_type(1,resnum) .eq. 'GLY') then
                        prcord(itg,resnum,1,2)=x
                        prcord(itg,resnum,2,2)=y
                        prcord(itg,resnum,3,2)=z
                        prcord(itg,resnum,1,6)=x
                        prcord(itg,resnum,2,6)=y
                        prcord(itg,resnum,3,6)=z
                        cordcnt(itg,resnum)=1.0
                endif

        elseif(atom_type .eq. 'CB') then
c          write(6,*)resnum,chain_id(1,resnum),
c     *     res_type(1,resnum),res_id(1,resnum),x,y,z
           if (res_type(1,resnum) .ne. 'GLY') then
              prcord(itg,resnum,1,2)=x
              prcord(itg,resnum,2,2)=y
              prcord(itg,resnum,3,2)=z
              prcord(itg,resnum,1,6)=prcord(itg,resnum,1,6)+x
              prcord(itg,resnum,2,6)=prcord(itg,resnum,2,6)+y
              prcord(itg,resnum,3,6)=prcord(itg,resnum,3,6)+z
              cordcnt(itg,resnum)=cordcnt(itg,resnum)+1.0
           endif
        elseif(atom_type .eq. 'O') then
           prcord(itg,resnum,1,3)=x
           prcord(itg,resnum,2,3)=y
           prcord(itg,resnum,3,3)=z
           
        elseif(atom_type .eq. 'N') then
           prcord(itg,resnum,1,4)=x
           prcord(itg,resnum,2,4)=y
           prcord(itg,resnum,3,4)=z

        elseif(atom_type .eq. 'C') then
           prcord(itg,resnum,1,5)=x
           prcord(itg,resnum,2,5)=y
           prcord(itg,resnum,3,5)=z

        elseif(atom_type.ne.'OT') then !side chain
           aa=atom_type
           if(aa.ne.'H') then
              prcord(itg,resnum,1,6)=prcord(itg,resnum,1,6)+x
              prcord(itg,resnum,2,6)=prcord(itg,resnum,2,6)+y
              prcord(itg,resnum,3,6)=prcord(itg,resnum,3,6)+z
              cordcnt(itg,resnum)=cordcnt(itg,resnum)+1.0
           endif
        endif


175     format(a4)
200     format(8x,I3,2x,a2,2x,a3,a2,a6,2x,f8.3,f8.3,f8.3)



        endif

        if (resnum .le. tgNres(1)) goto 135

250     continue

        do i=1,tgNres(1)
           if(cordcnt(itg,i).gt.0) then
            prcord(itg,i,1,6)=prcord(itg,i,1,6)/cordcnt(itg,i)
            prcord(itg,i,2,6)=prcord(itg,i,2,6)/cordcnt(itg,i)
            prcord(itg,i,3,6)=prcord(itg,i,3,6)/cordcnt(itg,i)
           elseif(prcord(itg,i,1,1).ne.0.0) then
            prcord(itg,i,1,6)=prcord(itg,i,1,1)
            prcord(itg,i,2,6)=prcord(itg,i,2,1)
            prcord(itg,i,3,6)=prcord(itg,i,3,1)
           elseif(prcord(itg,i,1,3).ne.0.0) then
            prcord(itg,i,1,6)=prcord(itg,i,1,3)
            prcord(itg,i,2,6)=prcord(itg,i,2,3)
            prcord(itg,i,3,6)=prcord(itg,i,3,3)
           elseif(prcord(itg,i,1,4).ne.0.0) then
            prcord(itg,i,1,6)=prcord(itg,i,1,4)
            prcord(itg,i,2,6)=prcord(itg,i,2,4)
            prcord(itg,i,3,6)=prcord(itg,i,3,4)
           else
            write(6,*) 'ERROR with coordinates'
            stop
           endif
c           if(itg.eq.2) write(6,60) i,'CA',res_type(1,i),i,
c     *          prcord(itg,i,1,1),prcord(itg,i,2,1),prcord(itg,i,3,1)
c           if(itg.eq.2) write(6,60) i,'CB',res_type(1,i),i,
c     *          prcord(itg,i,1,6),prcord(itg,i,2,6),prcord(itg,i,3,6)
        enddo

 60     format('ATOM',4x,I3,2x,a2,2x,a3,3x,I3,4x,f8.3,f8.3,f8.3,
     *       2x,'1.00',2x,'0.00',6x,'TPDB',1x)

        close(19)
        enddo !end numpdb

cccccccccccc set width cccccccccccc
        do i=1,maxres
            del=real(i)
            width(i)=1.0/(del**0.15)
         enddo

cccccccccccc find target contact matrix cccccccccccccccc
        dist(:,:,:,:)=0.0
        qi_cut(:,:)=0.0
        cntqi_cut(:,:)=0.0
        avg_qi_cut(:)=0.0
        cntavg_qi_cut(:)=0.0

        do id=1,2
         if(id.eq.1) then
              i1=1
              i2=1
              itab=1
         elseif(id.eq.2) then
              i1=6
              i2=6
              itab=4
         endif
         do i=1,tgNres(1)-1
           do j=i+1,tgNres(1)
              dist(0,i,j,itab)=sqrt( (prcord(0,i,1,i1)
     *           -prcord(0,j,1,i2))**2
     *           + (prcord(0,i,2,i1)
     *           -prcord(0,j,2,i2))**2
     *           + (prcord(0,i,3,i1)
     *           -prcord(0,j,3,i2))**2  )
              dist(0,j,i,itab)=dist(0,i,j,itab)
c      write(6,*) dist(0,i,j,itab),i,j
           enddo
         enddo
        enddo

cccccccccccc find qi's cccccccccccccccc                                                                                                                         

        do itg=1,numpdb
         do i=1,tgNres(1)
            do itab=1,1
               if(itab.eq.1) then
                  i1=1
                  i2=1
               elseif(itab.eq.2) then
                  i1=1
                  i2=6
               elseif(itab.eq.3) then
                  i1=6
                  i2=1
               else
                  i1=6
                  i2=6
               endif
               do j=1,tgNres(1)
                  if(abs(i-j).lt.2) cycle

                  dist(1,i,j,itab)=sqrt( (prcord(itg,i,1,i1)
     *             -prcord(itg,j,1,i2))**2
     *             + (prcord(itg,i,2,i1)
     *             -prcord(itg,j,2,i2))**2
     *             + (prcord(itg,i,3,i1)
     *             -prcord(itg,j,3,i2))**2  )
c           write(6,*) dist(1,i,j,itab),itab,i,j

                  del=(dist(0,i,j,itab)-dist(1,i,j,itab)) !0 is target, 1 is ensemble
     *                 *width(abs(j-i))

                  ! consider native contacts only: ca < 12
                  if(dist(0,i,j,itab).lt.rcut) then 
                     qi_cut(itg,i)=qi_cut(itg,i)+exp(-del*del*0.5)
                     cntqi_cut(itg,i)=cntqi_cut(itg,i)+1.0
                  endif
               enddo            ! end itab
            enddo               ! end j

            if (cntqi_cut(itg,i).gt.0) then
               qi_cut(itg,i)=qi_cut(itg,i)/cntqi_cut(itg,i)
               avg_qi_cut(i)=avg_qi_cut(i)+qi_cut(itg,i)
               cntavg_qi_cut(i)=cntavg_qi_cut(i)+1.0
            else
               qi_cut(itg,i)=1.1
            endif

        enddo                  ! end i

        ncount=itg
        call num_to_char(ncount,ccount)
        open(33,file='qi_'//trim(ccount)//'.dat', status='unknown')

        do i=1,tgNres(1)
           write(33,333) i,qi_cut(itg,i)
        enddo

        close(33)
 333    format(i6,1x,1(f9.4,2x))


        enddo !end numpdb

ccccccccccc print avg qi(i) over ensemble ccccccccccccc

        do i=1,tgNres(1)
           if (cntavg_qi_cut(i).gt.0) then
              avg_qi_cut(i)=avg_qi_cut(i)/cntavg_qi_cut(i)
           else
              avg_qi_cut(i)=1.1
           endif
        enddo

        open(33,file='qi_avg.dat', status='unknown')

        do i=1,tgNres(1)
           write(33,333) i,avg_qi_cut(i)
        enddo

        close(33)


        end


      subroutine num_to_char(count,ccount)

      implicit none
      integer count,i,j,k
      character ccount*10,c(10)

      ccount=' '

      if (iabs(count).gt.99999999) then
        write(6,*) 'number too large to convert',count
        stop
      endif

      j=0
      do while(count.ne.0)
        j=j+1

        i=mod(count,10)
        c(j)=char(i+48)
        count=(count-i)/10
      enddo

      do k=1,j
        ccount(j-k+1:j-k+1)=c(k)
      enddo
      return


      end
