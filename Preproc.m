pathtool

% This script extracts raw EEG data from .edf files and formats it into a
% fieldtrip-compatible dataset (.mat). This code is specifically designed
% to process the data from the EEG, Learning & KMI Study (Di Noto,
% Chartrand, Levkov, DeSouza, 2013-2014).

% Date start: 18Mar2014, version 08042014    ~Rodrigo Montefusco-Siegmund, Paula Di Noto~

ft_defaults
clear all, clc

cd('/Users/patriciozenteno/Downloads/Internship/longitudinal/'); % For Mac
FileList = dir('*.edf'); 

%% Load and read data
    FileName = FileList(NumFile).name;
    dat = ft_read_data(FileName);
    hdr = ft_read_header(FileName); 

%% Identify data markers and events of interest
    % Baseline
    BEOStart = find(datRS(36,:) == 34);  % Find marker (34) for start of baseline eyes open on channel 36 (Marker)
    BECStart = find(datRS(36,:) == 38);  % Baseline eyes closed
    BEOMStart = find(datRS(36,:) == 36);  % Baseline eyes open w/music
    BECMStart = find(datRS(36,:) == 42);  % Baseline eyes closed
    % Learning task
    L1Start = find(datRS(36,:) == 50);  % Block 1 (10x)
    L2Start = find(datRS(36,:) == 52);  % Block 2 (5x, 15T)
    L3Start = find(datRS(36,:) == 54);  % Block 3 (5x, 20T)
    L4Start = find(datRS(36,:) == 56);  % Block 4 (5x, 25T)
    LastStart = find(datRS(36,:) == 59);  % Last block (optional, 5x)
    % KMI Task
    KMIECStart = find(datRS(36,:) == 121);  % KMI eyes closed
    KMIEOStart = find(datRS(36,:) == 111);  % KMI eyes open (trials 1-25)

%% Epoching/segmentation

    BEO = {datRS(:,BEOStart:BEOStart+20*hdr.Fs)};   % Identify BEO epoch from BEOStart to BEOStart + 20sec*sampling rate
    BEOTrlInfo = ones(1,length(BEO))*1;

    BEC = {datRS(:,BECStart+3*hdr.Fs:BECStart+20*hdr.Fs)};% Identify BEC epoch from BECStart+3sec*samp rate (EC instructions) to BEOStart + 20sec*sampling rate
    BECTrlInfo = ones(1,length(BEC))*2;

    BEOM = {datRS(:,BEOMStart:BEOMStart+20*hdr.Fs)};
    BEOMTrlInfo = ones(1,length(BEOM))*3;

    BECM = {datRS(:,BECMStart+3*hdr.Fs:BECMStart+20*hdr.Fs)};
    BECMTrlInfo = ones(1,length(BECM))*4;

    L1 = {datRS(:,L1Start:L1Start+90*hdr.Fs)};
    L1TrlInfo = ones(1,length(L1))*5;
 
% Because subsequent learning blocks were presented based on subject responses,
    % the following loops will correct for missing blocks

    if ~isempty(L2Start)
        L2 = {datRS(:,L2Start:L2Start+45*hdr.Fs)};
        L2TrlInfo = ones(1,length(L2))*6;
    end

    if ~isempty(L3Start)
        L3 = {datRS(:,L3Start:L3Start+45*hdr.Fs)};
        L3TrlInfo = ones(1,length(L2))*7;
    end

    if ~isempty(L4Start)
        L4 = {datRS(:,L4Start:L4Start+45*hdr.Fs)};
        L4TrlInfo = ones(1,length(L4))*8;
    end

    if ~isempty(LastStart)
        Last = {datRS(:,LastStart:LastStart+45*hdr.Fs)};
        LastTrlInfo = ones(1,length(Last))*9;
    end

 % KMI
    KMIEC = [];
    for blk = 1:50
        KMIEC{blk} = datRS(:,KMIECStart(:,blk):KMIECStart(:,blk)+7*hdr.Fs);
    end
    KMIECTrlInfo = ones(1,length(KMIEC))*10;

% Because the 25 KMI Eyes Open trials were presented as a single video file (i.e., no markers between   
    % individual trials)
    % these loops will identify the segments of interest and
    % exclude the interstimulus intervals

    % Trial duration = 7.84seconds = 1004 samples = 8sec.
    % Interstimulus interval = 1.072sec = 137 samples = 1 sec.
    % Onset delay = 0.105sec = 13 samples

   KMIEO = [];
    Count = 1;
    for blk = 1:2
        TimeGap = 9*hdr.Fs; % Single KMI trial + ISI 
        for i = 1:25;
            if i == 1
                KMIEO{Count} = datRS(:,KMIEOStart(:,blk):KMIEOStart(:,blk)+(8*hdr.Fs)); % time stamp of trial 1; KMIEOStart+13 samples:KMIEOStart+1018 samples
                Count = Count+1;
            else
                KMIEO{Count} = datRS(:,(((KMIEOStart(:,blk))+(TimeGap*i-1)):((KMIEOStart(:,blk))+(TimeGap*i-1)+(8*hdr.Fs)))); % Start=(13 sample gap)+(time*previous trials), end=(13 sample gap)+(time*previous trials)+duration of 1 trials (in samples)
                Count = Count+1;
            end
        end
    end
    KMIEOTrlInfo = ones(1,length(KMIEO))*11;

 %% Defining trials based on learning task permutations
    if ~isempty(LastStart)  % Because seeing the clip one last time (block of 5 trials) was optional, our loop begins with if LastStart==1, or if LastStart is NOT empty, signified by the tilda (~)
        if ~isempty(L2Start)
            if ~isempty(L3Start)
                if ~isempty(L4Start)
                    BigData = [ BEO BEC BEOM BECM L1 L2 L3 L4 Last KMIEC KMIEO  ];
                    TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo L2TrlInfo L3TrlInfo L4TrlInfo LastTrlInfo KMIECTrlInfo KMIEOTrlInfo ]; 
                 % This version has all blocks of the learning task (i.e., if the subject viewed the learning   
                 video the max number of times)
                else
                    BigData = [ BEO BEC BEOM BECM L1 L2 L3 Last KMIEC KMIEO ];
                    TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo L2TrlInfo L3TrlInfo LastTrlInfo KMIECTrlInfo KMIEOTrlInfo ]; 
                   % Working one backwards in your if loop, this case will represent subjects
                   % that performed all blocks of the learning task except L4
                end 
                % Now that the preceding step of the if loop is satisfied, you have to indicate the end of   
                % this piece of the loop. Every if/else/elseif statement must be accompanied by an 'end', so  
                % make sure there is an 'end' for every 'if' statement in your loop
            else
                BigData = [ BEO BEC BEOM BECM L1 L2 Last KMIEC KMIEO ];
                TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo L2TrlInfo LastTrlInfo KMIECTrlInfo KMIEOTrlInfo ]; 
                % Working one step back in the if loop, this case has L1, L2 and Last but not L3 and L4
            end
        else
            BigData = [ BEO BEC BEOM BECM L1 Last KMIEC KMIEO ];
            TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo LastTrlInfo KMIECTrlInfo KMIEOTrlInfo ]; 
            % This is the last possible scenario; all subjects view L1, and this also fulfills the first line  
            % of the if loop, (if ~isempty(LastStart) )
        end
    else   % This is part of the initial if loop (i.e., if the subject responded No to watching the clip one last time)
        if ~isempty(L2Start)
            if ~isempty(L3Start)
                if ~isempty(L4Start)
                    BigData = [ BEO BEC BEOM BECM KMIEC KMIEO L1 L2 L3 L4 ];
                    TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo L2TrlInfo L3TrlInfo L4TrlInfo KMIECTrlInfo KMIEOTrlInfo ]; 
                    % This version has all blocks of the learning task (i.e., if the subject viewed the  
                    % learning video the max number of times WITHOUT opting to see the last block)
                else
                    BigData = [ BEO BEC BEOM BECM KMIEC KMIEO L1 L2 L3 ];
                    TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo L2TrlInfo L3TrlInfo KMIECTrlInfo KMIEOTrlInfo ];
                end
            else
                BigData = [ BEO BEC BEOM BECM KMIEC KMIEO L1 L2 ];
                TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo L2TrlInfo KMIECTrlInfo KMIEOTrlInfo ];
            end
        else
            BigData = [ BEO BEC BEOM BECM KMIEC KMIEO L1 ];
            TrlInfoVector = [ BEOTrlInfo BECTrlInfo BEOMTrlInfo BECMTrlInfo L1TrlInfo KMIECTrlInfo KMIEOTrlInfo ];
        end
    end

clear TimeLine

    for NumTrl = 1:length(BigData)
        TimeAux = 1/hdr.Fs:1/hdr.Fs:size(BigData{NumTrl},2)/hdr.Fs;
        TimeLine{NumTrl} = TimeAux;
    end

    data.fsample = hdr.Fs;
    data.label = hdr.label;
    data.trial = BigData;
    data.time = TimeLine;
    data.trialinfo = TrlInfoVector';
    cfg = [ ];
    cfg.channel = 3:16;
    cfg.demean = 'yes';
    [data] = ft_preprocessing(cfg,data);

    [a,b] = strtok(FileName,'-');
    matfile = fullfile('/Users/pauladinoto/Desktop/data/mat', [a '.mat']);
    save(matfile,'data');
    clear data

