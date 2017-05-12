clear;clc;close all;

judnum=1;%Pre-stored data for weave point classification
MethodInd=1;
%After weave point classification, 1 represents the weft float£¬2 represents
%the warp float£¬0 represents float unable to be recognized.
isshowpic=inputdlg('Show the phased image during process an example fabric or not:0 for No or 1 for yes£¨Default:0£©','Input Dialog');
if isempty(isshowpic{1}) || str2double(isshowpic{1})~=1
    isshowpic=0;
else
    isshowpic=1;
end

Method{1}='LFSMethod';
Method{2}='XiaosMethod';
Method{3}='ImprovedAjallouiansMethod';
Method{4}='ImprovedZhangsMethod';
Method{5}='ImprovedELMethod';
Method{6}='ImprovedIDMFMethod';
Method{7}='ImprovedGrayAutocorrMethod';
Method{8}='ImprovedPatAutocorrMethod';


imformat='.BMP';
if isshowpic==0
    MethodInd=inputdlg('Chose the method to recognize repeat size of weave pattern:1 for LFS method, 2 for Xiaos method, 3 for Improved Ajallouians method, 4 for Improved Zhangs method, 5 for Improved EL method, 6 for Improved IDMF method, 7 for Improved gray autocorrelation method, 8 for Improved pattern autocorrelation method','Input Dialog');%
    if isempty(MethodInd{1}) || str2double(MethodInd{1})<=1 || str2double(MethodInd{1})>8
        MethodInd=1;
    else
        MethodInd=str2double(MethodInd);
    end
    uigetfilename = 'Select any fabric image in the test picture data Folder';
else
    uigetfilename = 'Read a fabric image';
end

[image_name, imread_path] = uigetfile({'*.bmp';'*.jpg';'*.*'}, uigetfilename); %Select the file and folder of test data.
imwrite_path =strcat( '.\Resultdata\');% path to save the result
img_path_list = dir(strcat(imread_path,strcat('*',imformat)));%Read all files with '.BMP' form in test data folder.
img_num = length(img_path_list);%Get the number of test pictures.
Timtemp=zeros(1,img_num);

addpath( '.\CodeBesideMain\');
addpath(strcat( '.\',Method{MethodInd},'\Code\'));
if img_num > 0 
    if isshowpic==0
        fid=fopen(strcat(imwrite_path,'\ResultInfo.txt'),'w');
        fprintf(fid,'%s       %s    %s  \r\n','Image name','Warp number of each repeat','Weft number of each repeat');
        LoopBeg=1;
        LoopEnd=img_num;
    else
        LoopBeg=1;
        LoopEnd=1;
    end
    for k = LoopBeg:LoopEnd %read picture one by one
        if isshowpic==0
            image_name = img_path_list(k).name;
        end
        Orim =  imread(strcat(imread_path,image_name));
        disp(strcat('Processing',image_name));
        
       %%
        if exist('isshowpic','var') && isshowpic==1
            figure();
            imshow(Orim);
            hold on;
            title('Ô­Ê¼Í¼Ïñ');
        end
        
        Orim=double(Orim);
       %%
        im=Pretreat(Orim);  %Image pre-processing
        [Orim,im]=Inclinate(Orim,im,isshowpic); %Deviation correction
        [warpSeg,weftSeg]=waweSegment(im,isshowpic); %Weave point segmentation
        [warpSeg,weftSeg]=deaddedgesp(im,warpSeg,weftSeg,1); 
        
        estructpfea=getaspfeature(im,warpSeg,weftSeg,isshowpic); %Weave point feature extraction
        
       %%
        %Weave point classification using FCM
        [center, U, obj_fcn] = espfcm(estructpfea,2);
        espclare=espclassify(center,estructpfea);
        Caresult=judcencat(center,judnum,isshowpic);
        if isshowpic==1
            showPattern(im,warpSeg,weftSeg,espclare,Caresult);%show the pre-recgnized weave pattern,white areas for weft floats (1),balck areas for warp floats (0)
        end
        
       %%
        tic;
        switch MethodInd
            case 1
                [NumCowarp,NumCoweft]=GetWaWeCNumNS(warpSeg,weftSeg,estructpfea,isshowpic);
            case 2
                [NumCowarp,NumCoweft]=GetWaWeCycNum(warpSeg,weftSeg,estructpfea,isshowpic);
            case 3
                [NumCowarp,NumCoweft]=GetPRSize1stY(warpSeg,weftSeg,espclare,Caresult);
            case 4
                [NumCowarp,NumCoweft]=GetSRepUnit(warpSeg,weftSeg,espclare,Caresult,isshowpic);
            case 5
                [NumCowarp,NumCoweft]=GetPRSizeEL(warpSeg,weftSeg,espclare,Caresult);
            case 6
                [NumCowarp,NumCoweft]=GetPRSizeIDMF(im,warpSeg,weftSeg,isshowpic);
            case 7
                [NumCowarp,NumCoweft]=GetPRSizeAutoco(im,warpSeg,weftSeg,isshowpic);
            case 8
                [NumCowarp,NumCoweft]=GetPRSPatAutoco(warpSeg,weftSeg,espclare,Caresult,isshowpic);
        end
        toc
        Timtemp(k)=toc;
        Finalespclare=CorrectClass(warpSeg,weftSeg,NumCowarp,NumCoweft,espclare);%Correct weave pattern using the repeat size
        
       %%
        if isshowpic==1
            ShowFabricCycles(im,warpSeg,weftSeg,espclare,Caresult,NumCowarp,NumCoweft);%Show the weave pattern repeat
            if MethodInd==1
                showPattern(im,warpSeg,weftSeg,Finalespclare,Caresult);%Show the weave pattern
            end
        else
            fprintf(fid,'%s     %s                             %s           \r\n',image_name,num2str(NumCowarp),num2str(NumCoweft));
            PRImwrite_path=strcat(imwrite_path,'RepUnitDrawinOriginalImage\');
            SaveImPatRepRes(Orim,warpSeg,weftSeg,NumCowarp,NumCoweft,PRImwrite_path,image_name,imformat);
            RPPRImwrite_path=strcat(imwrite_path,'RepUnitDrawinPre-recognizedWeavePattern\');
            SaveRPPatRepRes(im,warpSeg,weftSeg,espclare,Caresult,NumCowarp,NumCoweft,RPPRImwrite_path,image_name,imformat);
            RPPRImwrite_path=strcat(imwrite_path,'RepUnitDrawinCorrectedWeavePattern\');
            SaveRPPatRepRes(im,warpSeg,weftSeg,Finalespclare,Caresult,NumCowarp,NumCoweft,RPPRImwrite_path,image_name,imformat);
        end
    end
    if isshowpic==0
        fclose(fid);
    end
else
    disp(strcat('In folder ',imread_path,' exist no file formed in ',imformat));
end

Meantime=mean(Timtemp);
disp(['Average time for weave pattern repeat recognition£º',num2str(Meantime),'s']);

