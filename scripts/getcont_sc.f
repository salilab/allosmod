        program getcont_sc

c prints out the res in structure 2 that interact (CA<rcut) with any res in structure 1

        parameter (maxres=10000)

        real prcord(2,maxres,3,6),x,y,z,cordcnt(2,maxres)

        character res_type(2,maxres)*3,atom_type*3,line_type*4,
     *       tres_type*3,res_id(2,maxres)*6,tres_id*6,tempr*6,aa*1

        integer atom_id,resnum,tgNres(2),isHET(2,maxres),tempisHET

        integer numcrd,numpro,nmdifv

        real class(20), rcut,dist(maxres,maxres,4)

        character profile(2)*200,chain_id(2,maxres)*2,tchain_id*2

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

       do itg=1,1
           read(12,33) profile(itg)
           read(12,*) tgNres(itg)
           read(12,*) rcut
        enddo
 33     format(a200)

        close(12)

        if(maxres.lt.tgNres(1).or.maxres.lt.tgNres(1)) then
           write(6,*) 'error getcontacts',tgNres(1:2),maxres
           stop
        endif

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc  get target coords cccccccccccccccccccccc

        prcord(1:2,:,1:3,1:5)=0.0
        prcord(1:2,:,1:3,6)=0.0
        cordcnt(1:2,:)=0.0
        isHET(1:2,:)=0
        do itg=1,1

         resnum = 0
         tempr=''

        open(19,file=trim(profile(itg)),status='old')

135     read(19,175,end=250) line_type

        if (line_type .eq. 'ATOM' .or.
     *       line_type .eq. 'HETA') then

           if(line_type.eq.'HETA') then
              tempisHET=1
           else
              tempisHET=0
           endif

        backspace 19

        read(19,200,end=250)atom_id,atom_type,
     *  tres_type,tchain_id,tres_id,x,y,z

        if(tempr.ne.tres_id) then
           tempr=tres_id
           resnum = resnum+1
           isHET(itg,resnum)=tempisHET
           res_type(itg,resnum)=tres_type
           chain_id(itg,resnum)=tchain_id
           res_id(itg,resnum)=tres_id
c        write(6,*)resnum,chain_id(itg,resnum),
c     *   res_type(itg,resnum),res_id(itg,resnum),x
           if(tres_type.eq.'HEM') then
              do i=1,3
                 isHET(itg,resnum+i)=tempisHET
                 res_type(itg,resnum+i)=tres_type
                 chain_id(itg,resnum+i)=tchain_id
                 res_id(itg,resnum+i)=tres_id
              enddo
              resnum=resnum+3 !go through entire heme entry in 4th index
              tgNres(itg)=tgNres(itg)+3 !account for heme with 4 residues
           endif
        endif

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
           if(res_type(itg,resnum).eq.'HEM') then 
              !heme has 4 indices, resnum is set to the 4th for entire heme entry
              if(atom_type.eq.'NA'.or.atom_type.eq.'C1A'.or.
     *             atom_type.eq.'C2A'.or.atom_type.eq.'C3A'.or.
     *             atom_type.eq.'C4A') then
                 prcord(itg,resnum-3,1,6)=prcord(itg,resnum-3,1,6)+x
                 prcord(itg,resnum-3,2,6)=prcord(itg,resnum-3,2,6)+y
                 prcord(itg,resnum-3,3,6)=prcord(itg,resnum-3,3,6)+z
                 cordcnt(itg,resnum-3)=cordcnt(itg,resnum-3)+1.0
              elseif(atom_type.eq.'NB'.or.atom_type.eq.'C1B'.or.
     *             atom_type.eq.'C2B'.or.atom_type.eq.'C3B'.or.
     *             atom_type.eq.'C4B') then
                 prcord(itg,resnum-2,1,6)=prcord(itg,resnum-2,1,6)+x
                 prcord(itg,resnum-2,2,6)=prcord(itg,resnum-2,2,6)+y
                 prcord(itg,resnum-2,3,6)=prcord(itg,resnum-2,3,6)+z
                 cordcnt(itg,resnum-2)=cordcnt(itg,resnum-2)+1.0
              elseif(atom_type.eq.'NC'.or.atom_type.eq.'C1C'.or.
     *             atom_type.eq.'C2C'.or.atom_type.eq.'C3C'.or.
     *             atom_type.eq.'C4C') then
                 prcord(itg,resnum-1,1,6)=prcord(itg,resnum-1,1,6)+x
                 prcord(itg,resnum-1,2,6)=prcord(itg,resnum-1,2,6)+y
                 prcord(itg,resnum-1,3,6)=prcord(itg,resnum-1,3,6)+z
                 cordcnt(itg,resnum-1)=cordcnt(itg,resnum-1)+1.0
              elseif(atom_type.eq.'ND'.or.atom_type.eq.'C1D'.or.
     *             atom_type.eq.'C2D'.or.atom_type.eq.'C3D'.or.
     *             atom_type.eq.'C4D') then
                 prcord(itg,resnum,1,6)=prcord(itg,resnum,1,6)+x
                 prcord(itg,resnum,2,6)=prcord(itg,resnum,2,6)+y
                 prcord(itg,resnum,3,6)=prcord(itg,resnum,3,6)+z
                 cordcnt(itg,resnum)=cordcnt(itg,resnum)+1.0
              endif
           else
              aa=atom_type
              if(aa.ne.'H') then
                 prcord(itg,resnum,1,6)=prcord(itg,resnum,1,6)+x
                 prcord(itg,resnum,2,6)=prcord(itg,resnum,2,6)+y
                 prcord(itg,resnum,3,6)=prcord(itg,resnum,3,6)+z
                 cordcnt(itg,resnum)=cordcnt(itg,resnum)+1.0
              endif
           endif
        endif


175     format(a4)
200     format(8x,I3,2x,a3,1x,a3,a2,a6,2x,f8.3,f8.3,f8.3)



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
c           if(itg.eq.2) write(6,60) i,'CA',res_type(itg,i),i,
c     *          prcord(itg,i,1,1),prcord(itg,i,2,1),prcord(itg,i,3,1)
c           if(itg.eq.2) write(6,60) i,'CB',res_type(itg,i),i,
c     *          prcord(itg,i,1,6),prcord(itg,i,2,6),prcord(itg,i,3,6)
        enddo

 60     format('ATOM',4x,I3,2x,a2,2x,a3,3x,I3,4x,f8.3,f8.3,f8.3,
     *       2x,'1.00',2x,'0.00',6x,'TPDB',1x)

        close(19)
        enddo !1,2


cccccccccccc find contact matrix cccccccccccccccc
c        rcut=8.0
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
         do i=1,tgNres(1)-3 !gt2
           do j=i+3,tgNres(1)
c         do i=1,tgNres(1)-1
c           do j=i+1,tgNres(1)
              if(isHET(1,i).eq.1.and.isHET(1,j).eq.1) cycle !do not print het het inx's
              dist(i,j,itab)=sqrt( (prcord(1,i,1,i1)
     *           -prcord(1,j,1,i2))**2
     *           + (prcord(1,i,2,i1)
     *           -prcord(1,j,2,i2))**2
     *           + (prcord(1,i,3,i1)
     *           -prcord(1,j,3,i2))**2  )
              if(dist(i,j,itab).gt.0.0.and.dist(i,j,itab).lt.rcut.and.
     *           (prcord(1,i,1,i1).ne.0.0.or.prcord(1,i,2,i1).ne.0.0.or.
     *            prcord(1,i,3,i1).ne.0.0).and.
     *           (prcord(1,j,1,i2).ne.0.0.or.prcord(1,j,2,i2).ne.0.0.or.
     *            prcord(1,j,3,i2).ne.0.0)) then
       call contact_type(res_type(1,i),res_type(1,j),ctype)
c           write(6,*) prcord(1,i,1,i2),prcord(1,j,1,i2),
c     *     res_id(1,i),chain_id(1,i),
c     *     res_type(1,j),dist(i,j,itab)
                 write(6,333) res_id(1,i),chain_id(1,i),
     *                res_id(1,j),chain_id(1,j),
     *                res_type(1,i),res_type(1,j),ctype,
     *                dist(i,j,itab),i1,i2
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
c          write(6,*) 'error getcontacts',res1,res2
c          stop
          c1=0
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
c          write(6,*) 'error getcontacts',res1,res2
c          stop
          c1=0
       endif


       if(c1.eq.2.and.c2.eq.2) ctype=1
       if(c1.eq.1.and.c2.eq.1) ctype=2
       if(c1.ne.c2) ctype=3

c     4 lett code H (hyrdophob), P (polar), A (acidic), K (basic)
c     hydrophilic (Ala, Gly, Pro, Ser, Thr)
c     hydrophobic (Cys, Ile, Leu, Met, Phe, Trp, Tyr, Val)
c     acidic (Asn, Asp, Gln, Glu)
c     basic (Arg, His, Lys)

      return
      end
