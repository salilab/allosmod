        program editrestraints
c NOTE****** DNA/RNA and hetatms only work when one template assigned (ie. not defined for multigaussians)
c creates restraint file by combining 2 restraint files: 1) used to define AS site 2) all others to define regulated region
c compile on 64 bit node: gfortran -mcmodel=medium editrestraints.f -o editrestraints
        parameter (maxparams=1000) ! max modality of a restraint
        parameter (maxatoms=78000)
        parameter (maxres=10001)
        parameter (maxbreak=4000)

        real amp(maxparams),d0(maxparams),sig(maxparams),
     *       rcut,dmin,dmax,hsig,x,y,z,
     *       d02(maxparams),sig2(maxparams),cor(maxparams),
     *       sig_AS,sig_RS,sig_inter,newsig,
     *       ntotal,delEmax,slope,scl_delx,HETscale,delEmaxNUC,
     *       rcutNUC,ndist,ndistCACB,bscale,sclbreak(maxbreak),delE,
     *       delEmaxLOC,seqdst,distco_scsc

        character restrfile(2)*400,type*2,pdbfile*400,
     *       contfile*400,chain*1,atomlistASRS*400,breakfile*400,
     *       atom_type*3,tres_type*3,tchain_id*2,line_type*4,
     *       allos_type*2,dummy*5000,dssp(maxres)*1,dsspfile*400

        integer i,j,nrestraints(2),iline,mfn2(3),ctr,ifile,
     *       natompdb,ncont,atom2RESTR(maxatoms),
     *       rcontmat(maxres,maxres),atom2res(maxatoms),ngood,
     *       natompdb2,atomisAS(maxatoms),iatom,natomRS,natomAS,
     *       atomisSC(maxatoms),newform,newpar,newmodal,tres_id,
     *       atomisCA(maxatoms),atomisCB(maxatoms),empty_AS,tgauss_AS,
     *       resnum,isHET,iminHET,isintra,nbreak,
     *       ibreak(maxbreak),isbreak,isNUC(maxatoms),rcoarse,locrigid,
     *       ndssp

        integer form,modal,feat,group,natom,nparam,nfeat,
     *       atom_id(10) !10=maxatoms per restraint

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc   Begin   cccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c     f77  pdb_2_movieseg.f -o pdb_2_movieseg.out

        open(12,file='targlist',status='old')

           read(12,*) restrfile(1) !first restrt file is for templates used for RS-RS contacts only (usually 2)
           read(12,*) nrestraints(1)
           read(12,*) restrfile(2) !second restrt file is for template used for AS-AS contacts and AS-RS interface contacts (usually 1)
           read(12,*) nrestraints(2)
           read(12,*) contfile
           read(12,*) ncont
           read(12,*) pdbfile
           read(12,*) natompdb
           read(12,*) atomlistASRS
           read(12,*) natompdb2
           read(12,*) sig_AS,sig_RS,sig_inter
           read(12,*) rcut !this is not used, defined in contfile
           read(12,*) ntotal
           read(12,*) delEmax,slope,scl_delx !if delEmax is zero, then use multi_gaussian, otherwise truncated_gaussian
           read(12,*) nbreak,breakfile
           read(12,*) rcoarse !equals 1 implies only apply distance restraint to CA's and CB's
           read(12,*) locrigid !equals 1 implies increase to local rigidity using CA restraints
           read(12,*) ndssp, dsspfile !number of dssp entries, dssp file (1 char per line corresponding to ss element)

        close(12)

        !if empty_AS, then only use: cov bonds, angles, dihedrals for AS
        !(ignore nonbonded contacts within AS site, RS and interface OK)
        empty_AS=0
        !if tgauss_AS, then AS nonbonded contacts are converted to truncated Gaussian, instead of being constrained
        tgauss_AS=1
        !scale intraHET contacts to prevent exploding 
        HETscale=1.0
        !set nucleotide energy params
        delEmaxNUC=0.12
        rcutNUC=8.0
        distco_scsc=5.0 !if test_nuc, must manually omit protein sc-sc interactions > 5 Ang
        !set local rigidity energy params
c        delEmaxLOC=delEmax*10.0 !currently set at isbreak options

cccccccccccc error check
        if(natompdb.ne.natompdb) then
           write(6,*) 'ERROR editrestraints: pdbfile not
     *          equal to atomlistASRS',
     *          natompdb,natompdb2
           stop
        endif
        if(natompdb.gt.maxatoms) then
           write(6,*) 'ERROR editrestraints: natompdb 
     *          greater than maxatoms',
     *          natompdb,maxatoms
           stop
        endif
        if(nbreak.gt.maxbreak) then
           write(6,*) 'ERROR editrestraints: nbreak 
     *          greater than maxbreak',
     *          nbreak,maxbreak
           stop
        endif

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

        write(6,*) 'MODELLER5 VERSION: MODELLER FORMAT'

cccccccccccc get res-res contact list cccccccccccc 
        open(20,file=trim(contfile),status='old')

        rcontmat(:,:)=0
        do iline=1,ncont
           read(20,*) i,chain,j,chain
           rcontmat(i,j)=1
           rcontmat(j,i)=1
        enddo
           
        close(20)

cccccccccccc get break.dat info ccccccccccccc
        !break.dat residues will have scaled distance interactions
        if(nbreak.gt.0) then
           open(20,file=trim(breakfile),status='old')
           do iline=1,nbreak
              read(20,*) ibreak(iline),sclbreak(iline)
           enddo
           close(20)
        endif

cccccccccccc get dssp info ccccccccccccc
        !one line per residue, index=res_id in input sequence
        if(ndssp.gt.0) then
           open(20,file=trim(dsspfile),status='old')
           do iline=1,ndssp
              read(20,*) dssp(iline)
           enddo
           close(20)
        endif

cccccccccccc get atom characteristics (atom2res, SC/BB, contact) ccccccccccc 

        open(111,file=trim(pdbfile),status='old')
 175    format(a4)
 200    format(8x,I3,2x,a3,1x,a3,a2,i6,2x,f8.3,f8.3,f8.3)

        atom2res(:)=0
        atomisSC(:)=0
        atomisCA(:)=0
        atomisCB(:)=0
        atom2RESTR(:)=0
        resnum=0
        isHET=0
        iminHET=999999
        isNUC(:)=0
        do iline=1,natompdb
           read(111,175) line_type
           if (line_type.eq.'ATOM'.or.line_type.eq.'HETA') then
              if (line_type.eq.'HETA') then
                 isHET=1
                 if(iline.lt.iminHET) iminHET=iline
              endif
              backspace 111
              read(111,200)atom_id(1),atom_type,
     *             tres_type,tchain_id,tres_id,x,y,z
           endif

           atom2res(iline)=tres_id !IMPORTANT: resID is read in from PDB file here, does not account for chains!

           if(tres_type.eq.'ADE'.or.tres_type.eq.'  A'.or.
     *          tres_type.eq.' DA'.or.tres_type.eq.'THY'.or.
     *          tres_type.eq.'  T'.or.tres_type.eq.' DT'.or.
     *          tres_type.eq.'URA'.or.tres_type.eq.'  U'.or.
     *          tres_type.eq.' DU'.or.tres_type.eq.'GUA'.or.
     *          tres_type.eq.'  G'.or.tres_type.eq.' DG'.or.
     *          tres_type.eq.'CYT'.or.tres_type.eq.'  C'.or.
     *          tres_type.eq.' DC') then
              isNUC(iline)=1
              do j=1,maxres
                 rcontmat(tres_id,j)=1
                 rcontmat(j,tres_id)=1
              enddo
           endif

           !determine backbone atoms (smaller sigma)
           if(atom_type.eq.'CA'.or.atom_type.eq.'CB'.or.
     *          atom_type.eq.'O'.or.atom_type.eq.'N'.or.
     *          atom_type.eq.'C'.or.atom_type.eq.'OT'.or. !heme core atoms
     *          atom_type.eq.'NA'.or.atom_type.eq.'NB'.or.
     *          atom_type.eq.'NC'.or.atom_type.eq.'ND'.or.
     *          atom_type.eq.'C1A'.or.atom_type.eq.'C2A'.or.
     *          atom_type.eq.'C3A'.or.atom_type.eq.'C4A'.or.
     *          atom_type.eq.'C1B'.or.atom_type.eq.'C2B'.or.
     *          atom_type.eq.'C3B'.or.atom_type.eq.'C4B'.or.
     *          atom_type.eq.'C1C'.or.atom_type.eq.'C2C'.or.
     *          atom_type.eq.'C3C'.or.atom_type.eq.'C4C'.or.
     *          atom_type.eq.'C1D'.or.atom_type.eq.'C2D'.or.
     *          atom_type.eq.'C3D'.or.atom_type.eq.'C4D'.or.
     *          ((tres_type.eq.'ADE'.or.tres_type.eq.'  A'.or. !nucleic acids
     *          tres_type.eq.' DA')).or.
     *          ((tres_type.eq.'THY'.or.tres_type.eq.'  T'.or.
     *          tres_type.eq.' DT')).or.
     *          ((tres_type.eq.'URA'.or.tres_type.eq.'  U'.or.
     *          tres_type.eq.' DU')).or.
     *          ((tres_type.eq.'GUA'.or.tres_type.eq.'  G'.or.
     *          tres_type.eq.' DG')).or.
     *          ((tres_type.eq.'CYT'.or.tres_type.eq.'  C'.or.
     *          tres_type.eq.' DC'))) then
              atomisSC(iline)=0

              if(atom_type.eq.'CA') 
     *             atomisCA(iline)=1
              if(atom_type.eq.'CB') 
     *             atomisCB(iline)=1

              !determine which nucleic acid atoms to restrain
              if(isNUC(iline).eq.1.and.
     *          ((tres_type.eq.'ADE'.or.tres_type.eq.'  A'.or.
     *          tres_type.eq.' DA').and.(atom_type.eq.'N1'.or.
     *          atom_type.eq.'C2'.or.atom_type.eq.'N3'.or.
     *          atom_type.eq.'C4'.or.atom_type.eq.'C5'.or.
     *          atom_type.eq.'C6'.or.atom_type.eq.'N6'.or.
     *          atom_type.eq.'N7'.or.atom_type.eq.'C8'.or.
     *          atom_type.eq.'N9')).or.
     *          ((tres_type.eq.'THY'.or.tres_type.eq.'  T'.or.
     *          tres_type.eq.' DT').and.(atom_type.eq.'N1'.or.
     *          atom_type.eq.'C2'.or.atom_type.eq.'O2'.or.
     *          atom_type.eq.'N1'.or.atom_type.eq.'N3'.or.
     *          atom_type.eq.'C4'.or.atom_type.eq.'O4'.or.
     *          atom_type.eq.'C5'.or.atom_type.eq.'C6'.or.
     *          atom_type.eq.'C7')).or.
     *          ((tres_type.eq.'URA'.or.tres_type.eq.'  U'.or.
     *          tres_type.eq.' DU').and.(atom_type.eq.'N1'.or.
     *          atom_type.eq.'C2'.or.atom_type.eq.'O2'.or.
     *          atom_type.eq.'N1'.or.atom_type.eq.'N3'.or.
     *          atom_type.eq.'C4'.or.atom_type.eq.'O4'.or.
     *          atom_type.eq.'C5'.or.atom_type.eq.'C6')).or.
     *          ((tres_type.eq.'GUA'.or.tres_type.eq.'  G'.or.
     *          tres_type.eq.' DG').and.(atom_type.eq.'N1'.or.
     *          atom_type.eq.'N2'.or.atom_type.eq.'C2'.or.
     *          atom_type.eq.'N2'.or.atom_type.eq.'N3'.or.
     *          atom_type.eq.'C4'.or.atom_type.eq.'C5'.or.
     *          atom_type.eq.'C6'.or.atom_type.eq.'O6'.or.
     *          atom_type.eq.'N7'.or.atom_type.eq.'C8'.or.
     *          atom_type.eq.'N9')).or.
     *          ((tres_type.eq.'CYT'.or.tres_type.eq.'  C'.or.
     *          tres_type.eq.' DC').and.(atom_type.eq.'N1'.or.
     *          atom_type.eq.'C2'.or.atom_type.eq.'O2'.or.
     *          atom_type.eq.'N3'.or.atom_type.eq.'C4'.or.
     *          atom_type.eq.'N4'.or.atom_type.eq.'C5'.or.
     *          atom_type.eq.'C6').or.
     *          atom_type.eq.'O1P'.or.atom_type.eq.'O2P'.or.
     *          atom_type.eq.'O3''')) then
                   atom2RESTR(iline)=1
              endif
           elseif(atom_type.ne.'H') then
              atomisSC(iline)=1
           endif
c       write(6,*)iline,'X',tres_type,'X',atom_type,'X',atomisSC(iline)
c       write(6,*)'YYY',iline,atomisCA(iline),atomisCB(iline)
        enddo

        close(111)

cccccccccccc get lists of AS and RS atoms 

        open(22,file=trim(atomlistASRS),status='old')

        atomisAS(iline)=0
        do iline=1,natompdb2
           read(22,*) i,allos_type
           if(allos_type.eq.'AS') then
              atomisAS(iline)=1
           elseif(allos_type.eq.'RS') then
              atomisAS(iline)=0
           else
              write(6,*) 'error in atomlistASRS'
              stop
           endif
        enddo

        close(22)

cccccccccccc if coarse grained distance restraints
        if (rcoarse.eq.1) then
           open(19,file=trim(restrfile(2)),status='old')
           read(19,*)           !skip line for header info

           !calculate number of distance contacts
           ndist=0
           ndistCACB=0
           do iline=1,nrestraints(2)
              read(19,*) type,form,modal,feat,group,natom,
     *             nparam,nfeat
              if (type .eq. 'R') backspace 19
              if (form.eq.3) then
                 read(19,*) type,form,modal,feat,group,natom,
     *                nparam,nfeat,atom_id(1:natom),
     *                d0(1),sig(1)
              elseif (form.eq.4) then
                 read(19,*) type,form,modal,feat,group,natom,
     *                nparam,nfeat,atom_id(1:natom),
     *                amp(1:modal),d0(1:modal),sig(1:modal)
              else
                 read(19,*)
              endif

              if ((form.eq.3.and.natom.eq.2.and.group.ne.1).or.
     *            (form.eq.4.and.natom.eq.2)) then
                 if(rcontmat(atom2res(atom_id(1)),
     *                atom2res(atom_id(2))).eq.1) then
                    if((atomisSC(atom_id(1)).ne.1.and.
     *                  atomisCB(atom_id(1)).ne.1).or.
     *                 (atomisSC(atom_id(2)).ne.1.and.
     *                  atomisCB(atom_id(2)).ne.1).or.
     *                 d0(1).le.distco_scsc) then !if test_nuc, omit side chain interactions > 5 Ang
                       ndist=ndist+1
                    endif
                    if ((atomisCA(atom_id(1)).eq.1.or.
     *                   atomisCB(atom_id(1)).eq.1.).and.
     *                  (atomisCA(atom_id(2)).eq.1.or.
     *                   atomisCB(atom_id(2)).eq.1.)) then
                       ndistCACB=ndistCACB+1
                    endif
                 endif
              endif
           enddo
           close(19)

           delEmax=(6.5/7.8)*(ndist/ndistCACB)*delEmax
         !(1.5+per_res_backbone_atoms)/per_res_atoms (ie backbone component + 1.5 for side chain)

           delEmaxNUC=(6.5/7.8)*(ndist/ndistCACB)*delEmaxNUC
        endif


cccccccccccccc  get restraints cccccccccccccccccccccc
      do ifile=1,2
        open(19,file=trim(restrfile(ifile)),status='old')
        read(19,*) !skip line for header info

        do iline=1,nrestraints(ifile)
           ! read in restraints
           read(19,*) type,form,modal,feat,group,natom,
     *          nparam,nfeat

           if (type .eq. 'R') then
              backspace 19

              if (form.eq.3) then
                 !gaussian, dist/angle/dihedral, 2 atoms
                 read(19,*) type,form,modal,feat,group,natom,
     *                nparam,nfeat,atom_id(1:natom),
     *                d0(1),sig(1)
              elseif (form.eq.4) then
                 !multigaussian, dist/dihedral, 2 atoms
                 read(19,*) type,form,modal,feat,group,natom,
     *                nparam,nfeat,atom_id(1:natom),
     *                      amp(1:modal),d0(1:modal),sig(1:modal)
              elseif (form.eq.7) then
                 !cosine, dihedral, 4 atoms 
                 read(19,*) type,form,modal,feat,group,natom,
     *                nparam,nfeat,atom_id(1:natom),
     *                d0(1),sig(1)
              elseif (form.eq.9) then
                 !multibinormal, dihedral, 8 atoms
                 !correlations between phi and psi angle for a given amino acid
                 read(19,*) type,form,modal,feat,group,natom,
     *                nparam,nfeat,mfn2(1:3),atom_id(1:natom),
     *                amp(1:modal),d0(1:modal),d02(1:modal),
     *                sig(1:modal),sig2(1:modal),cor(1:modal)
                 if(nfeat.gt.2) write(6,*)'nfeat too big'
                 if(nparam.gt.maxparams) write(6,*) 'nparam too big'
              elseif (form.eq.10) then
                 !read spline in like string, do not modify
                 read(19,'(a5000)') dummy
              else
                 write(6,*) 'missing form',form,feat
                 stop
              endif
           else
              write(6,*) 'not restraint'
              stop
           endif

cccccccccccc check if restraint should be outputed based on AS/RS critera cccccccccccc
           if(ifile.eq.1) then   
           !two template alignment, output (used for RS-RS contacts only)
              natomAS=0
              do iatom=1,natom
                 if(atomisAS(atom_id(iatom)).eq.1) natomAS=natomAS+1
              enddo
              if(natomAS.gt.0) cycle
           elseif(ifile.eq.2) then
           !single template alignment, output (used for AS-AS contacts and AS-RS interface contacts)
              natomRS=0
              do iatom=1,natom
                 if(atomisAS(atom_id(iatom)).eq.0) natomRS=natomRS+1 
              enddo
              if(natomRS.eq.natom) cycle
           endif

ccccccccccccccc error check ccccccccccccccccc

           if(atom2res(atom_id(1)).eq.0.or.
     *          atom2res(atom_id(2)).eq.0) then
              write(6,*) 'atom in restr file not in pdb file',
     *             atom_id(1),atom2res(atom_id(1)),
     *             atom_id(2),atom2res(atom_id(2))
              stop
           endif

cccccccccccc write out restraints cccccccccccccccc

 32    format(a1,1x,7(I4),2(I6),4x,3(f9.4,1x))
 33    format(a1,1x,7(I4),3(I6),4x,3(f9.4,1x))
 34    format(a1,1x,7(I4),4(I6),4x,3(f9.4,1x))
c 42    format(a1,1x,7(I4),2(I6),4x,9999(f9.4,1x))
 42    format(a1,1x,4(I4),I3,1x,2(I4),2(I6),4x,9999(f9.4,1x))
 43    format(a1,1x,7(I4),3(I6),4x,9999(f9.4,1x))
 44    format(a1,1x,7(I4),4(I6),4x,9999(f9.4,1x))
 74    format(a1,1x,7(I4),4(I6),4x,2(f9.4,1x))
 98    format(a1,1x,10(I4),8(I6),4x,9999(f9.4,1x))

       if (form.eq.3.and.natom.eq.2.and.group.eq.1) then
          !gaussian, dist restraint covalent bonds
          !keep as is for prot, scale for HET
          call is_intraHET_cont(atom_id,natom,iminHET,isintra)
          if(isintra.eq.0) then
             write(6,32) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig(1)
          else
             sig2(1)=sig(1) !*HETscale
             write(6,32) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig2(1)
          endif
       elseif (form.eq.3.and.natom.eq.2.and.group.ne.1) then
          !gaussian, dist restraint
          isbreak=0
          if(nbreak.gt.0) then !scale interactions for residues in break.dat
             bscale=1.0
             do i=1,nbreak
                if(atom2res(atom_id(1)).eq.ibreak(i).or.
     *               atom2res(atom_id(2)).eq.ibreak(i)) then
                   isbreak=1
                   bscale=bscale*sclbreak(i)
                endif
             enddo
          endif
c         if(isbreak.eq.1) cycle
          if(isbreak.eq.1) then 
             delE=bscale*delEmax
             delEmaxLOC=bscale*delEmax
          else
             delE=delEmax
             delEmaxLOC=delEmax*10.0
          endif

          if(rcoarse.eq.1) then !coarse grained landscape for CA and CB only
             if ((isNUC(atom_id(1)).ne.1.and.
     *            atomisCA(atom_id(1)).ne.1.and.
     *            atomisCB(atom_id(1)).ne.1.).or.
     *            (isNUC(atom_id(2)).ne.1.and.
     *            atomisCA(atom_id(2)).ne.1.and.
     *            atomisCB(atom_id(2)).ne.1.)) cycle
          endif

          !if test_nuc, omit side chain interactions > 5 Ang
          if((atomisSC(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1)
     *     .and.(atomisSC(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1)
     *     .and.d0(1).gt.distco_scsc) cycle 

          seqdst=sqrt((real(atom2res(atom_id(1)))-
     *           real(atom2res(atom_id(2))))**2)
          if(locrigid.eq.1.and.seqdst.le.5.and.seqdst.ge.2.and.
     *     (atomisCA(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1).and.
     *     (atomisCA(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1))then !if locrigid, treat local CA and CB contacts differently (short range)
c      write(6,*) 'XXX',atom2res(atom_id(1)),atom2res(atom_id(2)),
c     *            atomisCA(atom_id(1)),atomisCA(atom_id(2)),
c     *            atomisCB(atom_id(1)),atomisCB(atom_id(2))
             newpar=9
             newform=50
             newmodal=2
             amp(1)=0.5
             sig2(1)=2.0
             write(6,42) type,newform,newmodal,feat,group,
     *            natom,newpar,nfeat,atom_id(1:natom),
     *            delEmaxLOC,slope,scl_delx,
     *            amp(1),amp(1),d0(1),d0(1),sig2(1),sig2(1)
          elseif((locrigid.eq.1.and.seqdst.le.12.and.seqdst.ge.6.and.
c     *    (atomisCA(atom_id(1)).eq.1.and.atomisCA(atom_id(2)).eq.1).and.
     *     (atomisCA(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1).and.
     *     (atomisCA(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1).and.
     *     d0(1).lt.6.0).or.
     *     (ndssp.gt.0.and.seqdst.ge.2.and.d0(1).lt.6.0.and.
     *     (atomisCA(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1).and.
     *     (atomisCA(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1).and.
     *     (dssp(atom2res(atom_id(1))).eq.'E'.and.
     *      dssp(atom2res(atom_id(2))).eq.'E')))then        !if locrigid, treat local CA and CB contacts differently (med range)

c       if(dssp(atom2res(atom_id(1))).eq.'E'.and.
c     * dssp(atom2res(atom_id(2))).eq.'E'.and.
c     * seqdst.ge.2.and.d0(1).lt.rcut)
c     * write(6,*) 'YYY',atom2res(atom_id(1)),atom2res(atom_id(2)),
c     *            atomisCA(atom_id(1)),atomisCA(atom_id(2)),
c     *            atomisCB(atom_id(1)),atomisCB(atom_id(2))
             newpar=9
             newform=50
             newmodal=2
             amp(1)=0.5
             sig2(1)=2.0
             write(6,42) type,newform,newmodal,feat,group,
     *            natom,newpar,nfeat,atom_id(1:natom),
     *            delEmaxLOC,slope,scl_delx,
     *            amp(1),amp(1),d0(1),d0(1),sig2(1),sig2(1)
          elseif(rcontmat(atom2res(atom_id(1)),
     *         atom2res(atom_id(2))).eq.1) then

             if(isNUC(atom_id(1)).eq.0.and.isNUC(atom_id(2)).eq.0) then !intraprotein interaction

        call get_sig(atomisSC(atom_id(1)),atomisSC(atom_id(2)),
     *               atomisAS(atom_id(1)),atomisAS(atom_id(2)),
     *               ntotal,sig_AS,sig_RS,sig_inter,newsig)

               sig2(1)=newsig*(ntotal/1.0)**2

               if(atomisAS(atom_id(1)).eq.1.and. !Allosteric site
     *              atomisAS(atom_id(2)).eq.1) then
                  if(empty_AS.eq.0) then !skip if empty AS
                     if(tgauss_AS.eq.1) then !trucated Gaussian or constrained
                        !write as multigaussian to get converted properly into splines
                        newpar=9
                        newform=50
                        newmodal=2
                        amp(1)=0.5
                        write(6,42) type,newform,newmodal,feat,group,
     *                       natom,newpar,nfeat,atom_id(1:natom),
     *                       delE,slope,scl_delx,
     *                       amp(1),amp(1),d0(1),d0(1),sig2(1),sig2(1)
                     else
                        write(6,32) type,form,modal,feat,group,natom,
     *                       nparam,nfeat,atom_id(1:natom),
     *                       d0(1),sig2(1)
                     endif
                  endif
               else !RS or Interface: change to truncated_gaussian or multi_gaussian
                  if(delEmax.eq.0.0) then
                     newpar=3
                     newform=4
                     amp(1)=1.0
                     write(6,42) type,newform,modal,feat,group,natom,
     *                    newpar,nfeat,atom_id(1:natom),
     *                    amp(1),d0(1),sig2(1)
                  else
                     newpar=9
                     newform=50
                     newmodal=2
                     amp(1)=0.5
                     write(6,42) type,newform,newmodal,feat,group,
     *                    natom,newpar,nfeat,atom_id(1:natom),
     *                    delE,slope,scl_delx,
     *                    amp(1),amp(1),d0(1),d0(1),sig2(1),sig2(1)
                  endif
               endif

             elseif((isNUC(atom_id(1)).eq.1
     *               .and.isNUC(atom_id(2)).eq.0).or.
     *              (isNUC(atom_id(1)).eq.0
     *               .and.isNUC(atom_id(2)).eq.1)) then !protein-DNA interaction (trunc gauss)

                     if((isNUC(atom_id(1)).eq.1.and.
     *                   atom2RESTR(atom_id(1)).eq.1).or.
     *                  (isNUC(atom_id(2)).eq.1.and.
     *                   atom2RESTR(atom_id(2)).eq.1)) then
                       if(d0(1).lt.rcutNUC) then

        call get_sig(atomisSC(atom_id(1)),atomisSC(atom_id(2)),
     *               atomisAS(atom_id(1)),atomisAS(atom_id(2)),
     *               ntotal,sig_AS,sig_RS,sig_inter,newsig)

                        sig2(1)=newsig
                        newpar=9
                        newform=50
                        newmodal=2
                        amp(1)=0.5
                        write(6,42) type,newform,newmodal,feat,group,
     *                       natom,newpar,nfeat,atom_id(1:natom),
     *                       delEmaxNUC,slope,scl_delx,
     *                       amp(1),amp(1),d0(1),d0(1),sig2(1),sig2(1)
                       endif
                     endif

             else !intra-DNA interaction (harmonic restraints)
                if (atom2RESTR(atom_id(1)).eq.1.and.
     *               atom2RESTR(atom_id(2)).eq.1.and.
     *               d0(1).lt.rcutNUC) then
                   sig2(1)=1.0
                   write(6,32) type,form,modal,feat,group,natom,
     *                  nparam,nfeat,atom_id(1:natom),d0(1),sig2(1)
                endif
             endif
          endif
       elseif (form.eq.3.and.natom.eq.3) then
          !gaussian, angular restraint  
          !keep as is for protein, scale for HET
          call is_intraHET_cont(atom_id,natom,iminHET,isintra)
          if(isintra.eq.0) then
             write(6,33) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig(1)
          else
             sig2(1)=sig(1) !*HETscale
             write(6,33) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig2(1)
          endif
       elseif (form.eq.3.and.natom.eq.4) then
          !gaussian, torsion restraint
          !keep as is for protein, scale for HET
          call is_intraHET_cont(atom_id,natom,iminHET,isintra)
          if(isintra.eq.0) then
             write(6,34) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig(1)
          else
             sig2(1)=sig(1)*HETscale
             write(6,34) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig2(1)
          endif
       elseif (form.eq.4.and.natom.eq.2) then
          !multgaussian, dist restraint -> convert to truncated multigaussian
          isbreak=0
          if(nbreak.gt.0) then !scale interactions for residues in break.dat
             bscale=1.0
             do i=1,nbreak
                if(atom2res(atom_id(1)).eq.ibreak(i).or.
     *               atom2res(atom_id(2)).eq.ibreak(i)) then
                   isbreak=1
                   bscale=bscale*sclbreak(i)
                endif
             enddo
          endif
c          if(isbreak.eq.1) cycle
          if(isbreak.eq.1) then 
             delE=bscale*delEmax
             delEmaxLOC=bscale*delEmax
          else
             delE=delEmax
             delEmaxLOC=delEmax*10.0
          endif

          if(rcoarse.eq.1) then !coarse grained landscape for CA and CB only
             if ((isNUC(atom_id(1)).ne.1.and.
     *            atomisCA(atom_id(1)).ne.1.and.
     *            atomisCB(atom_id(1)).ne.1.).or.
     *            (isNUC(atom_id(2)).ne.1.and.
     *            atomisCA(atom_id(2)).ne.1.and.
     *            atomisCB(atom_id(2)).ne.1.)) cycle
          endif

          !if test_nuc, omit side chain interactions > 5 Ang
          if((atomisSC(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1)
     *     .and.(atomisSC(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1)
     *     .and.(d0(1).gt.distco_scsc.and.d0(2).gt.distco_scsc)) cycle 

          seqdst=sqrt((real(atom2res(atom_id(1)))-
     *           real(atom2res(atom_id(2))))**2)
          if(locrigid.eq.1.and.seqdst.le.5.and.seqdst.ge.2.and.
     *     (atomisCA(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1).and.
     *     (atomisCA(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1))then !if locrigid, treat local CA and CB contacts differently (short range)

            ngood=0
            do i=1,modal 
               ngood=ngood+1 
            enddo
            do i=1,modal
               amp(i)=1.0/real(ngood)
               d02(i)=d0(i)
               sig2(i)=2.0
            enddo
            if(ngood.gt.0) then
                  newpar=ngood*3+3
                  newform=50
                  write(6,42) type,newform,ngood,feat,group,natom,
     *              newpar,nfeat,atom_id(1:natom),
     *              delEmaxLOC,slope,scl_delx,
     *              amp(1:ngood),d02(1:ngood),sig2(1:ngood)
            endif

          elseif((locrigid.eq.1.and.seqdst.le.12.and.seqdst.ge.6.and.
c     *    (atomisCA(atom_id(1)).eq.1.and.atomisCA(atom_id(2)).eq.1).and.
     *     (atomisCA(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1).and.
     *     (atomisCA(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1).and.
     *     (d0(1).lt.6.0.or.d0(2).lt.6.0)).or.
     *     (ndssp.gt.0.and.seqdst.ge.2.and.
     *     (d0(1).lt.6.0.or.d0(2).lt.6.0).and.
     *     (atomisCA(atom_id(1)).eq.1.or.atomisCB(atom_id(1)).eq.1).and.
     *     (atomisCA(atom_id(2)).eq.1.or.atomisCB(atom_id(2)).eq.1).and.
     *     (dssp(atom2res(atom_id(1))).eq.'E'.and.
     *      dssp(atom2res(atom_id(2))).eq.'E')))then !if locrigid, treat local CA and CB contacts differently (med range)

            ngood=0
            do i=1,modal 
               ngood=ngood+1 
            enddo
            do i=1,modal
               amp(i)=1.0/real(ngood)
               d02(i)=d0(i)
               sig2(i)=2.0
            enddo
            if(ngood.gt.0) then
                  newpar=ngood*3+3
                  newform=50
                  write(6,42) type,newform,ngood,feat,group,natom,
     *              newpar,nfeat,atom_id(1:natom),
     *              delEmaxLOC,slope,scl_delx,
     *              amp(1:ngood),d02(1:ngood),sig2(1:ngood)
            endif

          elseif(rcontmat(atom2res(atom_id(1)),
     *         atom2res(atom_id(2))).eq.1) then

            ngood=0
            do i=1,modal 
               ngood=ngood+1 
            enddo
            if(ngood.gt.0) then
               ctr=0
               do i=1,modal
                     ctr=ctr+1
                     amp(ctr)=1.0/real(ngood)

        call get_sig(atomisSC(atom_id(1)),atomisSC(atom_id(2)),
     *               atomisAS(atom_id(1)),atomisAS(atom_id(2)),
     *               ntotal,sig_AS,sig_RS,sig_inter,newsig)

                     sig2(ctr)=newsig*(ntotal/real(ngood))**2
                     d02(ctr)=d0(i)
               enddo
c               if(atomisAS(atom_id(1)).eq.1.and. !error check
c     *              atomisAS(atom_id(2)).eq.1) then
c                  write(6,*) 'ERROR editrestraints: 
c     *                 AS should be defined by one PDB'
c                  stop
c               endif
               if(delEmax.eq.0.0) then !multi_gaussian
                  newpar=ngood*3
                  newform=4
                  write(6,42) type,newform,ngood,feat,group,natom,
     *              newpar,nfeat,atom_id(1:natom),
     *              amp(1:ngood),d02(1:ngood),sig2(1:ngood)
               else !truncated_gaussian
                  newpar=ngood*3+3
                  newform=50
                  write(6,42) type,newform,ngood,feat,group,natom,
     *              newpar,nfeat,atom_id(1:natom),
     *              delE,slope,scl_delx,
     *              amp(1:ngood),d02(1:ngood),sig2(1:ngood)
               endif
            endif
          endif
       elseif (form.eq.4.and.natom.eq.3) then
          !multgaussian, angular restraint
          !doesnt exist
          call is_intraHET_cont(atom_id,natom,iminHET,isintra)
          if(isintra.eq.0) then
             write(6,43) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            amp(1:modal),d0(1:modal),sig(1:modal)
          else
             do i=1,modal
                sig2(i)=sig(i) !*HETscale
             enddo
             write(6,43) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            amp(1:modal),d0(1:modal),sig2(1:modal)
          endif
       elseif (form.eq.4.and.natom.eq.4) then
          !multgaussian, torsion restraint
          !keep as is for prot, scale for HET
          call is_intraHET_cont(atom_id,natom,iminHET,isintra)
          if(isintra.eq.0) then
             write(6,44) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            amp(1:modal),d0(1:modal),sig(1:modal)
          else
             do i=1,modal
                sig2(i)=sig(i)*HETscale
             enddo
             write(6,44) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            amp(1:modal),d0(1:modal),sig2(1:modal)
          endif
       elseif (form.eq.7) then
          !cosine dihedrals for backbone dihedrals and 
          !side chain dihedrals with few alignments
          call is_intraHET_cont(atom_id,natom,iminHET,isintra)
          if(isintra.eq.0) then
             write(6,74) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig(1)
          else
             sig2(1)=sig(1)*HETscale
             write(6,74) type,form,modal,feat,group,natom,
     *            nparam,nfeat,atom_id(1:natom),
     *            d0(1),sig2(1)
          endif
       elseif (form.eq.9) then
          !binormal dihedrals for phi and psi angles
          !reweight so balance is uniform
c          amp(1:modal)=1/real(modal)
c          sig(1:modal)=0.25
c          sig2(1:modal)=0.25
          !keep as is
c          write(6,98) type,form,modal,feat,group,natom,
c     *         nparam,nfeat,mfn2(1:3),atom_id(1:natom),
c     *         amp(1:modal),d0(1:modal),d02(1:modal),
c     *         sig(1:modal),sig2(1:modal),cor(1:modal)
       elseif (form.eq.10) then
          write(6,*) trim(dummy)
       else
          write(6,*) 'missing form',form,feat,natom
          stop
       endif

!     add intra heme contacts to maintain geometry (not included above due to contmap), keep all as is
       if(isHET.eq.1) then
        call is_intraHET_cont(atom_id,natom,iminHET,isintra)
        if(isintra.eq.1) then
           if (form.eq.3.and.natom.eq.2.and.group.ne.1) then
              !gaussian, dist restraint
              sig2(1)=sig(1) !*HETscale
              write(6,32) type,form,modal,feat,group,natom,
     *             nparam,nfeat,atom_id(1:natom),
     *             d0(1),sig2(1)
           elseif (form.eq.4.and.natom.eq.2) then
              !multgaussian, dist restraint
              do i=1,modal
                 sig2(i)=sig(i) !*HETscale
              enddo
              write(6,42) type,form,modal,feat,group,natom,
     *             nparam,nfeat,atom_id(1:natom),
     *             amp(1:modal),d0(1:modal),sig2(1:modal)      
           endif
        endif
       endif

      enddo                     !end restraints   
      close(19)

      enddo ! end ifile

cccccccccccccccc add restraints to CA's enforce boundary conditions: cube soft boundary
      type='R'
      modal=0
      group=27
      natom=1
      nparam=2
      nfeat=1
      d0(1)=100.0               !xyz radius
      sig2(1)=10.0              !strength of boundary
      d0(2)=-1*d0(1)
      do i=1,natompdb
         if(atomisCA(i).eq.1) then
            do j=9,11
               feat=j
               form=2
               write(6,21) type,form,modal,feat,group,natom,
     *              nparam,nfeat,i,
     *              d0(1),sig2(1)
               form=1
               write(6,21) type,form,modal,feat,group,natom,
     *              nparam,nfeat,i,
     *              d0(2),sig2(1)
            enddo
         endif
      enddo
 21   format(a1,1x,7(I4),I6,4x,2(f9.4,1x))

      end


      subroutine is_intraHET_cont(atom_id,natom,iminHET,isintra)

      implicit none
      integer natom,atom_id(10),isintra,natomPROT,iatom,iminHET

      isintra=0
      natomPROT=0
      do iatom=1,natom
         if(atom_id(iatom).lt.iminHET) natomPROT=natomPROT+1
      enddo

      if(natomPROT.eq.0) isintra=1

      return

      end



      subroutine get_sig(atomisSC1,atomisSC2,atomisAS1,atomisAS2,
     *                   ntotal,sig_AS,sig_RS,sig_inter,newsig)

      implicit none
      integer atomisSC1,atomisSC2,atomisAS1,atomisAS2
      
      real sig_AS,sig_RS,sig_inter,sig_scale,
     *     ntotal,newsig

      if(atomisSC1.eq.0.and.atomisSC2.eq.0) then !BB-BB
         sig_scale=1.0
      elseif((atomisSC1.eq.0.and.atomisSC2.eq.1).or.
     *        (atomisSC1.eq.1.and.atomisSC2.eq.0)) then !SC-BB
         sig_scale=1.5
      else                      !SC-SC
         sig_scale=1.5*1.5
      endif

      if (atomisAS1.eq.1.and.atomisAS2.eq.1) then
         if(ntotal.eq.1) then   !if one template, avoid treating like AS
            newsig=sig_AS*sig_scale
         else                   !if allosteric site, do not scale interactions for side chains
            newsig=sig_AS
         endif
      elseif(atomisAS1.eq.0.and.atomisAS2.eq.0) then
         newsig=sig_RS*sig_scale
      else                      !interface
         newsig=sig_inter*sig_scale
      endif
c      write(6,*)atomisSC1,atomisSC2,atomisAS1,atomisAS2,sig_scale,newsig
c     *     ,ntotal
      return


      end
