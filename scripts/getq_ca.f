        program getq_ca

c prints out the res in structure 2 that interact (CA<rcut) with any res in structure 1
c compile on 64 bit node: gfortran -mcmodel=medium getq_ca.f -o getq_ca
        parameter (maxres=10001)
        parameter (maxpdb=3001)

        real prcord(0:maxpdb,maxres,3,6),x,y,z,cordcnt(0:maxpdb,maxres)

        character res_type(2,maxres)*3,atom_type*2,line_type*4,
     *       tres_type*3,res_id(2,maxres)*6,tres_id*6,tempr*6,aa*1,
     *       ccount1*10,ccount2*10

        integer atom_id,resnum,tgNres(2),ncount1,ncount2

        integer numcrd,numpro,nmdifv,numpdb,res_start,res_end

        real class(20), rcut,dist(0:1,maxres,maxres,4),del,
     *       width(maxres),q_cut(maxpdb),
     *       cntq_cut(maxpdb),q_tot(maxpdb),cntq_tot(maxpdb),
     *       qs_tot(maxpdb),cntqs_tot(maxpdb),
     *       qm_tot(maxpdb),cntqm_tot(maxpdb),
     *       ql_tot(maxpdb),cntql_tot(maxpdb),
     *       qs_cut(maxpdb),cntqs_cut(maxpdb),
     *       qm_cut(maxpdb),cntqm_cut(maxpdb),
     *       ql_cut(maxpdb),cntql_cut(maxpdb)   

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
        read(12,*) tgNres(1),res_start,res_end
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
        q_cut(:)=0.0
        cntq_cut(:)=0.0
        q_tot(:)=0.0
        cntq_tot(:)=0.0
        qs_tot(:)=0.0
        cntqs_tot(:)=0.0
        qm_tot(:)=0.0
        cntqm_tot(:)=0.0
        ql_tot(:)=0.0
        cntql_tot(:)=0.0
        qs_cut(:)=0.0
        cntqs_cut(:)=0.0
        qm_cut(:)=0.0
        cntqm_cut(:)=0.0
        ql_cut(:)=0.0
        cntql_cut(:)=0.0

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
         do i=res_start,res_end-2
           do j=i+2,res_end
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

cccccccccccc find q's cccccccccccccccc                                                                                                                         

        do itg=1,numpdb
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
           do i=res_start,res_end-2
              do j=i+2,res_end
c                  if(abs(i-j).lt.2) cycle

                  dist(1,i,j,itab)=sqrt( (prcord(itg,i,1,i1)
     *             -prcord(itg,j,1,i2))**2
     *             + (prcord(itg,i,2,i1)
     *             -prcord(itg,j,2,i2))**2
     *             + (prcord(itg,i,3,i1)
     *             -prcord(itg,j,3,i2))**2  )
c           write(6,*) dist(1,i,j,itab),itab,i,j

                  del=(dist(0,i,j,itab)-dist(1,i,j,itab)) !0 is target, 1 is ensemble
     *                 *width(abs(j-i))

                  ! consider native contacts only: ca < rcut
                  if(dist(0,i,j,itab).lt.rcut) then 
                     q_cut(itg)=q_cut(itg)+exp(-del*del*0.5)
                     cntq_cut(itg)=cntq_cut(itg)+1.0
                     if(abs(i-j).lt.5) then
                        qs_cut(itg)=qs_cut(itg)+exp(-del*del*0.5)
                        cntqs_cut(itg)=cntqs_cut(itg)+1.0
                     elseif(abs(i-j).lt.13) then
                        qm_cut(itg)=qm_cut(itg)+exp(-del*del*0.5)
                        cntqm_cut(itg)=cntqm_cut(itg)+1.0
                     else
                        ql_cut(itg)=ql_cut(itg)+exp(-del*del*0.5)
                        cntql_cut(itg)=cntql_cut(itg)+1.0                     
                     endif
                  endif
                  q_tot(itg)=q_tot(itg)+exp(-del*del*0.5)
                  cntq_tot(itg)=cntq_tot(itg)+1.0
                  if(abs(i-j).lt.5) then
                     qs_tot(itg)=qs_tot(itg)+exp(-del*del*0.5)
                     cntqs_tot(itg)=cntqs_tot(itg)+1.0
                  elseif(abs(i-j).lt.13) then
                     qm_tot(itg)=qm_tot(itg)+exp(-del*del*0.5)
                     cntqm_tot(itg)=cntqm_tot(itg)+1.0
                  else
                     ql_tot(itg)=ql_tot(itg)+exp(-del*del*0.5)
                     cntql_tot(itg)=cntql_tot(itg)+1.0
                  endif

               enddo            ! end j
            enddo               ! end i

        enddo                  ! end tab

        !normalize
        if(cntq_cut(itg).gt.0.0) then
           q_cut(itg)=q_cut(itg)/cntq_cut(itg)
        else
           q_cut(itg)=0.0
        endif
        if(cntq_tot(itg).gt.0.0) then
           q_tot(itg)=q_tot(itg)/cntq_tot(itg)
        else
           q_tot(itg)=0.0
        endif
        if(cntqs_cut(itg).gt.0.0) then
           qs_cut(itg)=qs_cut(itg)/cntqs_cut(itg)
        else
           qs_cut(itg)=0.0
        endif
        if(cntqm_cut(itg).gt.0.0) then
           qm_cut(itg)=qm_cut(itg)/cntqm_cut(itg)
        else
           qm_cut(itg)=0.0
        endif
        if(cntql_cut(itg).gt.0.0) then
           ql_cut(itg)=ql_cut(itg)/cntql_cut(itg)
        else
           ql_cut(itg)=0.0
        endif
        if(cntqs_tot(itg).gt.0.0) then
           qs_tot(itg)=qs_tot(itg)/cntqs_tot(itg)
        else
           qs_tot(itg)=0.0
        endif
        if(cntqm_tot(itg).gt.0.0) then
           qm_tot(itg)=qm_tot(itg)/cntqm_tot(itg)
        else
           qm_tot(itg)=0.0
        endif
        if(cntql_tot(itg).gt.0.0) then
           ql_tot(itg)=ql_tot(itg)/cntql_tot(itg)
        else
           ql_tot(itg)=0.0
        endif

        enddo !end numpdb

ccccccccccc print q ccccccccccccc

        ncount1=res_start
        ncount2=res_end
        call num_to_char(ncount1,ccount1)
        call num_to_char(ncount2,ccount2)

        open(33,file='qscore'//trim(ccount1)//'to'//trim(ccount2)//
     *           '.dat', status='unknown')
        do i=1,numpdb
           write(33,333) i,q_tot(i),qs_tot(i),qm_tot(i),ql_tot(i)
        enddo
 333    format(i6,1x,4(f9.4,2x))
        close(33)

        open(34,file='qs_cut'//trim(ccount1)//'to'//trim(ccount2)//
     *           '.dat', status='unknown')
        do i=1,numpdb
           write(34,333) i,q_cut(i),qs_cut(i),qm_cut(i),ql_cut(i)
        enddo
 334    format(i6,1x,4(f9.4,2x))
        close(34)

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
