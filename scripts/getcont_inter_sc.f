        program getcont_cacb

c prints out the res in structure 2 that interact (CA<rcut) with any res in structure 1

        parameter (maxres=10001)

        real prcord(2,maxres,3,6),x,y,z,cordcnt(2,maxres)

        character res_type(2,maxres)*3,atom_type*2,line_type*4,
     *       tres_type*3,res_id(2,maxres)*6,tres_id*6,tempr*6,aa*1

        integer atom_id,resnum,tgNres(2),isHET(maxres)

        integer numcrd,numpro,nmdifv

        real class(20), rcut,dist(maxres,maxres,4)

        character profile(2)*200,chain_id(2,maxres)*2,tchain_id*2

        integer itg,Ntg,id,i,j,ctype,i1,i2,itab,iout,jout

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

       do itg=1,2
           read(12,33) profile(itg)
           read(12,*) tgNres(itg)
        enddo
        read(12,*) rcut
 33     format(a200)

        close(12)

        if(maxres.lt.tgNres(1).or.maxres.lt.tgNres(2)) then
           write(6,*) 'error getcontacts',tgNres(1:2),maxres
           stop
        endif

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc  get target coords cccccccccccccccccccccc

        prcord(1:2,:,1:3,1:5)=1.0
        prcord(1:2,:,1:3,6)=0.0
        cordcnt(1:2,:)=0.0
        isHET(:)=0
        do itg=1,2

         resnum = 0
         tempr=''

        open(19,file=trim(profile(itg)),status='old')

135     read(19,175,end=250) line_type

        if (line_type .eq. 'ATOM' .or.
     *       line_type .eq. 'HETA' ) then

        backspace 19

        read(19,200,end=250)atom_id,atom_type,
     *  tres_type,tchain_id,tres_id,x,y,z

        if(tempr.ne.tres_id.and.tres_type.ne.'HOH') then
           tempr=tres_id
           resnum = resnum+1
           res_type(itg,resnum)=tres_type
           chain_id(itg,resnum)=tchain_id
           res_id(itg,resnum)=tres_id
c        write(6,*)resnum,chain_id(itg,resnum),
c     *   res_type(itg,resnum),res_id(itg,resnum),x
        endif

        if(line_type .eq. 'HETA') then
           if(tres_type .ne. 'HOH') then
           isHET(resnum)=1
           prcord(itg,resnum,1,6)=prcord(itg,resnum,1,6)+x
           prcord(itg,resnum,2,6)=prcord(itg,resnum,2,6)+y
           prcord(itg,resnum,3,6)=prcord(itg,resnum,3,6)+z
           cordcnt(itg,resnum)=cordcnt(itg,resnum)+1.0
           endif
        else !ATOM
         if(tres_type.ne.'ALA'.and.tres_type.ne.'GLY'
     *          .and.tres_type.ne.'PRO'.and.tres_type.ne.'LEU'.and.
     *      tres_type.ne.'SER'.and.tres_type.ne.'THR'
     *          .and.tres_type.ne.'ASN'.and.tres_type.ne.'MET'.and.
     *      tres_type.ne.'ASP'.and.tres_type.ne.'GLN'
     *          .and.tres_type.ne.'GLU'.and.tres_type.ne.'PHE'.and.
     *      tres_type.ne.'ARG'.and.tres_type.ne.'HIS'
     *          .and.tres_type.ne.'LYS'.and.tres_type.ne.'TRP'.and.
     *      tres_type.ne.'HSD'.and.tres_type.ne.'CYS'
     *          .and.tres_type.ne.'ILE'.and.tres_type.ne.'TYR'.and.
     *          tres_type.ne.'VAL') isHET(resnum)=1

         if(atom_type .eq. 'CA') then
         prcord(itg,resnum,1,1)=x
         prcord(itg,resnum,2,1)=y
         prcord(itg,resnum,3,1)=z
                if (res_type(itg,resnum) .eq. 'GLY') then
                        prcord(itg,resnum,1,2)=x
                        prcord(itg,resnum,2,2)=y
                        prcord(itg,resnum,3,2)=z
                        prcord(itg,resnum,1,6)=x
                        prcord(itg,resnum,2,6)=y
                        prcord(itg,resnum,3,6)=z
                        cordcnt(itg,resnum)=1.0
                endif

         elseif(atom_type .eq. 'CB') then
c          write(6,*)resnum,chain_id(itg,resnum),
c     *     res_type(itg,resnum),res_id(itg,resnum),x,y,z
           if (res_type(itg,resnum) .ne. 'GLY') then
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
        endif !end hetatm

175     format(a4)
200     format(8x,I3,2x,a2,2x,a3,a2,a6,2x,f8.3,f8.3,f8.3)



        endif

        if (resnum .le. tgNres(itg)) goto 135

250     continue

        do i=1,tgNres(itg)
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
c           write(6,60) i,'SC',res_type(itg,i),i,
c     *          prcord(itg,i,1,6),prcord(itg,i,2,6),prcord(itg,i,3,6)
        enddo

 60     format('ATOM',4x,I3,2x,a2,2x,a3,3x,I3,4x,f8.3,f8.3,f8.3,
     *       2x,'1.00',2x,'0.00',6x,'TPDB',1x)

c     no longer checking, approximate number is ok
c        if(resnum.ne.tgNres(itg)) then 
c           write(6,*) 'problem getcontacts',resnum,tgNres(itg),itg
c           stop
c        endif

        close(19)
        enddo !1,2


cccccccccccc find contact matrix cccccccccccccccc
c        rcut=6.5
        dist(:,:,:)=0.0

        do itab=4,4
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
         do i=1,tgNres(1)
            if(isHET(i).eq.1) then
               iout=0
            else
               iout=i1
            endif
           do j=1,tgNres(2)
              if(isHET(j).eq.1) then
                 jout=0
              else
                 jout=i2
              endif
              dist(i,j,itab)=sqrt( (prcord(1,i,1,i1)
     *           -prcord(2,j,1,i2))**2
     *           + (prcord(1,i,2,i1)
     *           -prcord(2,j,2,i2))**2
     *           + (prcord(1,i,3,i1)
     *           -prcord(2,j,3,i2))**2  )
c           write(6,*) prcord(1,i,1,i2),prcord(2,j,1,i2),
c     *     res_id(1,i),chain_id(1,i),res_id(2,j),chain_id(2,j),
c     *     res_type(2,j)
              if(dist(i,j,itab).lt.rcut.and.
     *         (prcord(1,i,1,i1).ne.1.0.or.prcord(1,i,2,i1).ne.1.0.or.
     *         prcord(1,i,3,i1).ne.1.0).and.(prcord(2,j,1,i2).ne.1.0.or.
     *         prcord(2,j,2,i2).ne.1.0.or.prcord(2,j,3,i2).ne.1.0)) then
       call contact_type(res_type(1,i),res_type(2,j),ctype)
                 write(6,333) res_id(1,i),chain_id(1,i),
     *                res_id(2,j),chain_id(2,j),
     *                res_type(1,i),res_type(2,j),ctype,
     *                dist(i,j,itab),iout,jout
              endif
           enddo
         enddo
        enddo

 333    format(2(2x,a6,2x,a2),2(2x,a3),i3,f11.3,2(2x,i1))

        end



      subroutine contact_type(res1,res2,ctype)

      character res1*3,res2*3
      integer ctype, c1,c2

c     ctype code: 1)hphob-hphob 2) charge/polar-charge/polar 3) hphob-charge/polar
      c1=0
      c2=0
      ctype=0

       if(res1.eq.'ALA'.or.res1.eq.'GLY'.or.res1.eq.'PRO'.or.
     *      res1.eq.'SER'.or.res1.eq.'THR'.or.res1.eq.'ASN'.or.
     *      res1.eq.'ASP'.or.res1.eq.'GLN'.or.res1.eq.'GLU'.or.
     *      res1.eq.'ARG'.or.res1.eq.'HIS'.or.res1.eq.'LYS'.or.
     *      res1.eq.'HSD') then
          c1=1
       elseif(res1.eq.'CYS'.or.res1.eq.'ILE'.or.
     *         res1.eq.'LEU'.or.
     *      res1.eq.'MET'.or.res1.eq.'PHE'.or.res1.eq.'TRP'.or.
     *      res1.eq.'TYR'.or.res1.eq.'VAL') then 
          c1=2
       else
          c1=0
c          write(6,*) 'error getcontacts',res1,res2
c          stop
       endif
       if(res2.eq.'ALA'.or.res2.eq.'GLY'.or.res2.eq.'PRO'.or.
     *      res2.eq.'SER'.or.res2.eq.'THR'.or.res2.eq.'ASN'.or.
     *      res2.eq.'ASP'.or.res2.eq.'GLN'.or.res2.eq.'GLU'.or.
     *      res2.eq.'ARG'.or.res2.eq.'HIS'.or.res2.eq.'LYS'.or.
     *      res2.eq.'HSD') then
          c2=1
       elseif(res2.eq.'CYS'.or.res2.eq.'ILE'.or.
     *         res2.eq.'LEU'.or.
     *      res2.eq.'MET'.or.res2.eq.'PHE'.or.res2.eq.'TRP'.or.
     *      res2.eq.'TYR'.or.res2.eq.'VAL') then
          c2=2
       else
          c2=0
c          write(6,*) 'error getcontacts',res1,res2
c          stop
       endif


       if(c1.eq.2.and.c2.eq.2) ctype=1
       if(c1.eq.1.and.c2.eq.1) ctype=2
       if(c1.ne.c2) ctype=3
       if(c1.eq.0.or.c2.eq.0) ctype=0

c     4 lett code H (hyrdophob), P (polar), A (acidic), K (basic)
c     hydrophilic (Ala, Gly, Pro, Ser, Thr)
c     hydrophobic (Cys, Ile, Leu, Met, Phe, Trp, Tyr, Val)
c     acidic (Asn, Asp, Gln, Glu)
c     basic (Arg, His, Lys)

      return
      end
