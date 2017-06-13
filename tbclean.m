function tbclean
%TBCLEAN   Removes HyEQ_Toolbox_V2_04.
%    TBCLEAN removes all files of HyEQ_Toolbox_V2_04 from
%    the filesystem and its entry from the Matlab
%    startup file.
%    
%    This installation script was generated by using 
%    the MAKEINSTALL tool. For further information
%    visit http://matlab.pucicu.de

% Copyright (c) 2008-2012
% Norbert Marwan, Potsdam Institute for Climate Impact Research, Germany
% http://www.pik-potsdam.de
%
% Copyright (c) 2002-2008
% Norbert Marwan, Potsdam University, Germany
% http://www.agnld.uni-potsdam.de
%
% Generation date: 12-Jun-2017 14:37:58
% $Date: 2014/09/04 07:33:00 $
% $Revision: 3.33 $

error(nargchk(0,0,nargin));

try
  if isoctave
      more off
  end
  fid = 0;
  warning('off')
  disp('-----------------------------------')
  disp('    REMOVING HyEQ_Toolbox_V2_04    ')
  disp('-----------------------------------')
  currentpath=pwd;
  oldtoolboxpath = fileparts(which(mfilename));

  disp(['  HyEQ_Toolbox_V2_04 found in ', oldtoolboxpath,''])
  i = input('> Delete HyEQ_Toolbox_V2_04? Y/N [Y]: ','s');
  if isempty(i), i = 'Y'; end

  if strcmpi('Y',i)
%%%%%%% check for entries in startup
  
        p=path; i1=0; i = ''; number_warnings_pathdef = 0;
  
        while findstr(upper('HyEQ_Toolbox_V2_04'),upper(p)) > i1
           i1=findstr(upper('HyEQ_Toolbox_V2_04'),upper(p));
           if ~isempty(i1)
               i1=i1(end);
               if isunix, i2=findstr(':',p); else, i2=findstr(';',p); end
               i3=i2(i2>i1);                 % last index pathname
               if ~isempty(i3), i3=i3(1)-1; else, i3=length(p); end
               i4=i2(i2<i1);                 % first index pathname
               if ~isempty(i4), i4=i4(end)+1; else, i4=1; end
               rmtoolboxpath=p(i4:i3);
%%%%%%% removing entry in startup-file
               rmpath(rmtoolboxpath)
               err = savepath;
               if number_warnings_pathdef == 0 && err, disp('  ** Warning: No write access to pathdef.m file!'), number_warnings_pathdef = number_warnings_pathdef+1; end
               if i4>1, p(i4-1:i3)=''; else, p(i4:i3)=''; end
               startup_exist = exist('startup','file');
               if isoctave startup_exist = exist(fullfile('~','.octaverc'),'file'); end
               if startup_exist
                    startupfile=which('startup');
                    startuppath=startupfile(1:findstr('startup.m',startupfile)-1);
                    if isoctave
                        startuppath = ['~',filesep];
                        startupfile = fullfile('~','.octaverc');
                    end
                    fid = fopen(startupfile,'r');
                    k = 1;
                    while 1
                       tmp = fgetl(fid);
                       if ~ischar(tmp), break, end
                       instpaths{k} = tmp;
                       k = k + 1;
                    end
                    k=1;
                    while k <= length(instpaths)
                        if ~isempty(findstr(rmtoolboxpath,instpaths{k}))
                            disp(['  Removing startup entry ', instpaths{k}])
                            instpaths(k)=[];
                        end
                        k=k+1;
                    end
                    fid=fopen(startupfile,'w');
                    for i2=1:length(instpaths), 
                        fprintf(fid,'%s\n', char(instpaths{i2})); 
                    end
                    fclose(fid);
               end
           end
           p = path; i1 = 0;
       end
%%%%%%% removing old paths
        if exist(oldtoolboxpath,'dir') == 7
           if isoctave, confirm_recursive_rmdir (false, 'local'); end
           disp(['  Removing files in ',oldtoolboxpath,''])
           cd(oldtoolboxpath)
           dirnames='';filenames='';
           temp='.:';
           while ~isempty(temp)
               [temp1 temp]=strtok(temp,':');
               if ~isempty(temp1)
                   dirnames=[dirnames; {temp1}];
                   x2=dir(temp1);
                   for i=1:length(x2)
                       if ~x2(i).isdir, filenames=[filenames; {[temp1,'/', x2(i).name]}]; end
         	             if x2(i).isdir && ~strcmp(x2(i).name,'.') && ~strcmp(x2(i).name,'..'), temp=[temp,temp1,filesep,x2(i).name,':']; end
                   end
               end
           end
           dirnames = strrep(dirnames,['.',filesep],'');
           dirnames(strcmpi('.',dirnames)) = [];
           l = zeros(length(dirnames),1); for i=1:length(dirnames),l(i)=length(dirnames{i}); end
           [i i4]=sort(l); i4 = i4(:);
           dirnames=dirnames(flipud(i4));
           for i=1:length(dirnames)
              delete([dirnames{i}, filesep,'*'])
              if exist('rmdir') == 5 && exist(dirnames{i}) == 7, rmdir(dirnames{i},'s'); else, delete(dirnames{i}), end
              disp(['  Removing files in ',char(dirnames{i}),''])
           end
           if exist(currentpath), cd(currentpath), else, cd .., end
           if strcmpi(currentpath,oldtoolboxpath), cd .., end
           if exist('rmdir') == 5 && exist(oldtoolboxpath) == 7, rmdir(oldtoolboxpath,'s'); else, delete(oldtoolboxpath), end
           disp(['  Removing folder ',oldtoolboxpath,''])
        end
       disp(['  HyEQ_Toolbox_V2_04 now removed.'])
  else
       disp(['  Nothing happened. Keep smiling.'])
  end
  tx=version; tx=strtok(tx,'.'); if str2double(tx)>=6 && exist('rehash','builtin'), rehash, end
  warning on
  if isoctave
      more on
  end
  if exist(currentpath,'dir') ~= 7, cd(fileparts(currentpath)), else, cd(currentpath), end
  
%%%%%%% error handling

catch
  x=lasterr;y=lastwarn;
  if ~strcmpi(lasterr,'Interrupt')
    if fid>-1, 
      try, z=ferror(fid); catch, z='No error in the installation I/O process.'; end
    else
      z='File not found.'; 
    end
    fid=fopen('deinstall.log','w');
    fprintf(fid,'%s\n','A critical error has occurred. Please inform the distributor');
    fprintf(fid,'%s\n','of the toolbox, where the error occured and send us the entire');
    fprintf(fid,'%s\n','screen output of the installation, the following error');
    fprintf(fid,'%s\n','report, and the informations about the toolbox (distributor,');
    fprintf(fid,'%s\n','name, URL etc.). Provide a brief description of what you were');
    fprintf(fid,'%s\n','doing when this problem occurred.');
    fprintf(fid,'%s\n','E-mail or FAX this information to us at:');
    fprintf(fid,'%s\n','    E-mail:  marwan@pik-potsdam.de');
    fprintf(fid,'%s\n','       Fax:  ++49 +331 288 2640');
    fprintf(fid,'%s\n\n\n','Thank you for your assistance.');
    fprintf(fid,'%s\n',repmat('-',50,1));
    fprintf(fid,'%s\n',datestr(now,0));
    fprintf(fid,'%s\n',['Matlab ',char(version),' on ',computer]);
    fprintf(fid,'%s\n',repmat('-',50,1));
    fprintf(fid,'%s\n','HyEQ_Toolbox_V2_04');
    fprintf(fid,'%s\n',x);
    fprintf(fid,'%s\n',y);
    fprintf(fid,'%s\n',z);
    fclose(fid);
    disp('----------------------------');
    disp('       ERROR OCCURED ');
    disp('   during deinstallation');
    disp('----------------------------');
    disp(x);
    disp(z);
    disp('----------------------------');
    disp('   A critical error has occurred. Please inform the distributor');
    disp('   of the toolbox, where the error occured and send us the entire');
    disp('   screen output of the installation, the error report report');
    disp('   and the informations about the toolbox (distributor, name,');
    disp('   URL etc.). For your convenience, this information has been')
    disp('   recorded in: ')
    disp(['   ',fullfile(pwd,'deinstall.log')]), disp(' ')
    disp('   Provide a brief description of what you were doing when ')
    disp('   this problem occurred.'), disp(' ')
    disp('   E-mail or FAX this information to us at:')
    disp('       E-mail:  marwan@pik-potsdam.de')
    disp('          Fax:  ++49 +331 288 2640'), disp(' ')
    disp('   Thank you for your assistance.')
  end
  warning('on')
  if exist(currentpath,'dir') == 7, cd(fileparts(currentpath)), else, cd(currentpath), end
  if isoctave
      more on
  end
end

function flag = isoctave
% ISOCTAVE   Checks whether the code is running in Octave
%   ISOCTAVE is returning the value TRUE if executed within the
%   Octave environment, else it is returning FALSE (e.g. when
%   called within Matlab.

a = ver('Octave');

if ~isempty(a) && strfind(a(1).Name,'Octave')
    flag = true;
else
    flag = false;
end
