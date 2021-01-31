P = mfilename('fullpath');
[pth, filename]=fileparts(P);
codedir=pth;
addpath /home/wang/workshop/spm12/
varnames=parsevariables('smokingvar.m');
datroot='/home/wang/workshop/hcp/UBENMAPS_AVG';
imgtype={'s_rfMRI_REST1', 's_rfMRI_REST2'}
session={''}
resdir_root ='/home/wang/workshop/hcp/USTATS_Csm';

T=readtable('RESTRICTED_zewang_2_20_2018_13_41_12.xlsx');
maskimg=fullfile(codedir, 'ch2betmask.nii');
% get BEN maps for non-smokers and smokers
age=T.Age_in_Yrs;
gender=T.Gender;
edu=T.SSAGA_Educ;
varnames={'edu' 'age' 'gender'}
allcon=[0 1 0 0 ];
subjlist=T.Subject;
% for reg=1:length(varnames)   % age gender and edu
    statdir_var=fullfile(resdir_root, 'edusexage');
    mkdir(resdir_root, 'edusexage');
    for mv=1%:length(imgtype)
        for ses=1:length(session)
            cd(codedir);
            P1=[];
            a1=[];
            a2=[];
            a3=[];
            
            for s=1:size(subjlist,1)
                if isnan(subjlist(s)) continue; end
                if isempty(subjlist(s)) continue; end
                
                f1=spm_select('FPList', datroot, ['^' imgtype{1} '.*' num2str(subjlist(s)) '.*' session{ses}  '.*\.nii$']);
                if isempty(f1) continue; end
                f2=spm_select('FPList', datroot, ['^' imgtype{2} '.*' num2str(subjlist(s)) '.*' session{ses}  '.*\.nii$']);
                if isempty(f2) continue; end
                file=spm_select('FPList', datroot, ['^' imgtype{mv} '.*' num2str(subjlist(s)) '.*' session{ses}  '.*\.nii$']);
%                 if isempty(file) continue; end
                P1=strvcat(P1, file);
                a1=cat(1,a1, age(s));
                if gender{s}=='M'
                    a2=cat(1,a2, -1);
                else
                    a2=cat(1,a2, 1);   % female = 1
                end
                a3=cat(1,a3, edu(s));
            end
            
            loc=(isnan(a1)|isnan(a2)|isnan(a3))<1;
%             loc=isnan(var)<1;
%             var=var(loc);
            P1=P1(loc, :);
            a1=a1(loc,:);
            a2=a2(loc,:);
            a3=a3(loc,:);
            clear scans
            for im=1:size(P1,1)
                scans{im, 1}=deblank(P1(im,:));
            end
            statdir=fullfile(statdir_var, [imgtype{mv} '_' session{ses} '_n' num2str(size(P1,1))]);
            mkdir(statdir_var, [imgtype{mv} '_' session{ses} '_n' num2str(size(P1,1))]);
        
            cd(statdir);
            spm_unlink(fullfile('.', 'SPM.mat')); % avoid overwrite dialog

            matlabbatch{1}.spm.stats.factorial_design.dir = {statdir};
            matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = scans;
            matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov = struct('c', {}, 'cname', {}, 'iCC', {});
            matlabbatch{1}.spm.stats.factorial_design.des.mreg.incint = 1;


            matlabbatch{1}.spm.stats.factorial_design.cov(1).c = a3;
            matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'edu';
            matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;
            matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;
            matlabbatch{1}.spm.stats.factorial_design.cov(2).c = a1;
            matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'age';
            matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI = 1;
            matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;
            
            matlabbatch{1}.spm.stats.factorial_design.cov(3).c = a2;
            matlabbatch{1}.spm.stats.factorial_design.cov(3).cname = 'sex';
            matlabbatch{1}.spm.stats.factorial_design.cov(3).iCFI = 1;
            matlabbatch{1}.spm.stats.factorial_design.cov(3).iCC = 1;
            matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
            matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
            matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
            matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskimg};
            matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
            matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
            matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
             cfg_util('run', matlabbatch);
            clear matlabbatch;
              cd(statdir);  
                load SPM.mat

                % Estimate parameters
                SPM = spm_spm(SPM);
                load SPM.mat
                xcon_1 = length(SPM.xCon)+1;

                          % now put T contrast per row into SPM structure
                     for cn = 1:size(allcon,1)
                         if cn==1&& (isempty(SPM.xCon))                 % setting for spm5
                            SPM.xCon=spm_FcUtil('Set',...
                                             'change',...
                                             'T',...
                                             'c',...
                                             allcon(cn,:)', ...
                                             SPM.xX.xKXs);
                         else
                           SPM.xCon(end + 1)= spm_FcUtil('Set',...
                                              'change',...
                                             'T',...
                                             'c',...
                                             allcon(cn,:)', ...
                                             SPM.xX.xKXs);
                         end
                   end

                % Estimate only the contrasts we've added
                spm_contrasts(SPM, xcon_1:xcon_1+size(allcon,1)-1);
                clear matlabbatch;
        end
    end

    
