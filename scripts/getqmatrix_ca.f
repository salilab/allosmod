        program getqmatrix_ca

c prints out the res in structure 2 that interact (CA<rcut) with any res in structure 1
c compile on 64 bit node: gfortran -mcmodel=medium getqmatrix_ca.f -o getqmatrix_ca
c        parameter (maxres=2001) 
c        parameter (maxpdb=501) !2000*2000*500 needs 7G of memory
        parameter (maxres=10001) 
        parameter (maxpdb=11) !10001*10001*11 needs 4G of memory

        real prcord(maxres,3,6),x,y,z,cordcnt(maxres)

        character res_type(maxres)*3,atom_type*2,line_type*4,
     *       tres_type*3,res_id(maxres)*6,tres_id*6,tempr*6,aa*1,
     *       ccount1*10,ccount2*10

        integer atom_id,resnum,tgNres(2),ncount1,ncount2

        integer numcrd,numpro,nmdifv,numpdb,res_start,res_end

        real class(20), rcut,dist(0:maxpdb,maxres,maxres),del,
     *       width(maxres),q_cut(maxpdb,maxpdb),
     *       cntq_cut,q_tot(maxpdb,maxpdb),cntq_tot

        character profile(0:maxpdb)*200,chain_id(maxres)*2,tchain_id*2

        integer itg,jtg,Ntg,id,i,j,ctype,i1,i2,itab

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

        read(12,*) tgNres(1),res_start,res_end
        read(12,*) rcut
        read(12,*) numpdb

        do itg=1,numpdb
           read(12,33) profile(itg) !ensemble proteins
        enddo
 33     format(a200)

        close(12)

        if(maxres.lt.tgNres(1).or.maxres.lt.tgNres(1)) then
           write(6,*) 'error getqmatrix',tgNres(1),maxres
           stop
        endif
        if(maxpdb.lt.numpdb) then
           write(6,*) 'error getqmatrix',numpdb,maxpdb
           stop
        endif


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc  get target coords cccccccccccccccccccccc

        prcord(:,1:3,1:5)=9999.9999
        prcord(:,1:3,6)=0.0
        cordcnt(:)=0.0
        do itg=1,numpdb

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
           res_type(resnum)=tres_type
           chain_id(resnum)=tchain_id
           res_id(resnum)=tres_id
c        write(6,*)resnum,chain_id(resnum),
c     *   res_type(resnum),res_id(resnum),x
        endif

        if(atom_type .eq. 'CA'.or.atom_type .eq. 'P') then
        prcord(resnum,1,1)=x
        prcord(resnum,2,1)=y
        prcord(resnum,3,1)=z
                if (res_type(resnum) .eq. 'GLY') then
                        prcord(resnum,1,2)=x
                        prcord(resnum,2,2)=y
                        prcord(resnum,3,2)=z
                        prcord(resnum,1,6)=x
                        prcord(resnum,2,6)=y
                        prcord(resnum,3,6)=z
                        cordcnt(resnum)=1.0
                endif

        elseif(atom_type .eq. 'CB') then
c          write(6,*)resnum,chain_id(resnum),
c     *     res_type(resnum),res_id(resnum),x,y,z
           if (res_type(resnum) .ne. 'GLY') then
              prcord(resnum,1,2)=x
              prcord(resnum,2,2)=y
              prcord(resnum,3,2)=z
              prcord(resnum,1,6)=prcord(resnum,1,6)+x
              prcord(resnum,2,6)=prcord(resnum,2,6)+y
              prcord(resnum,3,6)=prcord(resnum,3,6)+z
              cordcnt(resnum)=cordcnt(resnum)+1.0
           endif
        elseif(atom_type .eq. 'O') then
           prcord(resnum,1,3)=x
           prcord(resnum,2,3)=y
           prcord(resnum,3,3)=z
           
        elseif(atom_type .eq. 'N') then
           prcord(resnum,1,4)=x
           prcord(resnum,2,4)=y
           prcord(resnum,3,4)=z

        elseif(atom_type .eq. 'C') then
           prcord(resnum,1,5)=x
           prcord(resnum,2,5)=y
           prcord(resnum,3,5)=z

        elseif(atom_type.ne.'OT') then !side chain
           aa=atom_type
           if(aa.ne.'H') then
              prcord(resnum,1,6)=prcord(resnum,1,6)+x
              prcord(resnum,2,6)=prcord(resnum,2,6)+y
              prcord(resnum,3,6)=prcord(resnum,3,6)+z
              cordcnt(resnum)=cordcnt(resnum)+1.0
           endif
        endif


175     format(a4)
200     format(8x,I3,2x,a2,2x,a3,a2,a6,2x,f8.3,f8.3,f8.3)



        endif

        if (resnum .le. tgNres(1)) goto 135

250     continue

        do i=1,tgNres(1)
           if(cordcnt(i).gt.0) then
            prcord(i,1,6)=prcord(i,1,6)/cordcnt(i)
            prcord(i,2,6)=prcord(i,2,6)/cordcnt(i)
            prcord(i,3,6)=prcord(i,3,6)/cordcnt(i)
           elseif(prcord(i,1,1).ne.0.0) then
            prcord(i,1,6)=prcord(i,1,1)
            prcord(i,2,6)=prcord(i,2,1)
            prcord(i,3,6)=prcord(i,3,1)
           elseif(prcord(i,1,3).ne.0.0) then
            prcord(i,1,6)=prcord(i,1,3)
            prcord(i,2,6)=prcord(i,2,3)
            prcord(i,3,6)=prcord(i,3,3)
           elseif(prcord(i,1,4).ne.0.0) then
            prcord(i,1,6)=prcord(i,1,4)
            prcord(i,2,6)=prcord(i,2,4)
            prcord(i,3,6)=prcord(i,3,4)
           else
            write(6,*) 'ERROR with coordinates'
            stop
           endif
c           if(itg.eq.2) write(6,60) i,'CA',res_type(i),i,
c     *          prcord(i,1,1),prcord(i,2,1),prcord(i,3,1)
c           if(itg.eq.2) write(6,60) i,'CB',res_type(i),i,
c     *          prcord(i,1,6),prcord(i,2,6),prcord(i,3,6)
        enddo

 60     format('ATOM',4x,I3,2x,a2,2x,a3,3x,I3,4x,f8.3,f8.3,f8.3,
     *       2x,'1.00',2x,'0.00',6x,'TPDB',1x)

        close(19)

        !save distances
        do i=res_start,res_end-2
           do j=i+2,res_end
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
          
              dist(itg,i,j)=sqrt( (prcord(i,1,i1)
     *             -prcord(j,1,i2))**2
     *             + (prcord(i,2,i1)
     *             -prcord(j,2,i2))**2
     *             + (prcord(i,3,i1)
     *             -prcord(j,3,i2))**2  )
           enddo
           enddo
        enddo

        enddo !end numpdb

cccccccccccc set width cccccccccccc
        do i=1,maxres
            del=real(i)
            width(i)=1.0/(del**0.15)
         enddo

cccccccccccc find q's cccccccccccccccc                                                                                                                         

        q_cut(:,:)=0.0
        q_tot(:,:)=0.0

        do itg=1,numpdb-1
          do jtg=itg+1,numpdb

           cntq_cut=0.0
           cntq_tot=0.0

              do i=res_start,res_end-2
                 do j=i+2,res_end

                    del=(dist(itg,i,j)-dist(jtg,i,j)) !0 is target, 1 is ensemble
     *                   *width(abs(j-i))

                    ! consider native contacts only: ca < rcut
                    if(dist(itg,i,j).lt.rcut.or.
     *                   dist(jtg,i,j).lt.rcut) then 
                       q_cut(itg,jtg)=q_cut(itg,jtg)+exp(-del*del*0.5)
                       cntq_cut=cntq_cut+1.0
                    endif
c                    q_tot(itg,jtg)=q_tot(itg,jtg)+exp(-del*del*0.5)
c                    cntq_tot=cntq_tot+1.0
                    
                 enddo          ! end j
              enddo             ! end i

        !normalize
        if(cntq_cut.gt.0.0) then
           q_cut(itg,jtg)=q_cut(itg,jtg)/cntq_cut
           q_cut(jtg,itg)=q_cut(itg,jtg)
        else
           q_cut(itg,jtg)=0.0
           q_cut(jtg,itg)=0.0
        endif
c        if(cntq_tot.gt.0.0) then
c           q_tot(itg,jtg)=q_tot(itg,jtg)/cntq_tot
c           q_tot(jtg,itg)=q_tot(itg,jtg)
c        else
c           q_tot(itg,jtg)=0.0
c           q_tot(jtg,itg)=0.0
c        endif

        enddo !end jtg
      enddo !end itg

ccccccccccc print q ccccccccccccc

c        open(33,file='qmatrix.dat', status='unknown')
c        do i=1,numpdb
c           do j=1,numpdb
c              if(i.ne.j) then
c                 write(33,333) q_tot(i,j)
c              else
c                 q_tot(i,j)=1.0
c                 write(33,333) q_tot(i,j)
c              endif
c           enddo
c        enddo
 333    format(f9.4)
c        close(33)

        open(34,file='qcut_matrix.dat', status='unknown')
        do i=1,numpdb
           do j=1,numpdb
              if(i.ne.j) then
                 write(34,333) q_cut(i,j)
              else
                 q_cut(i,j)=1.0
                 write(34,333) q_cut(i,j)
              endif
           enddo
        enddo
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
