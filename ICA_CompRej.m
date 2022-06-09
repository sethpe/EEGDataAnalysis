%% This script will epoch all segments of the newly-converted .mat file
% into 2-second epochs, perform a bandpass filter, ICA, and artifact
% rejection of visually inspected artifacts. Preprocessed data will be
% saved with the suffix '_CompRej.mat' into the same mat directory for
% further analyses. 

% Adapted to EEG, Learning and KMI Study 21.04.2014, Rodrigo Montefusco-Siegmund, Gaby Levkov & Paula Di Noto 

clear all, clc;
ft_defaults;

% Load the .mat file as a variable in Matlab workspace
FileName = '12051'; %write name of data file


%% Redefine each trial into epochs of 2 seconds
cfg = [ ];
cfg.length = 2;
cfg.minlength = 2;
dataredef = ft_redefinetrial(cfg,data);


%% Bandpass filter
cfg = [ ];
cfg.bpfilter        = 'yes';
cfg.bpfreq          = [1 50];
cfg.bptype          = 'but';
cfg.bpfiltord       = 2;
cfg.bpfiltdir       = 'twopass';
cfg.demean          = 'yes';
cfg.detrend         = 'yes';

[preproc] = ft_preprocessing(cfg, dataredef);

%% Visual inspection and artifact rejection
cfg          = [ ];
cfg.method   = 'summary';
cfg.layout   = 'biosemi64.lay';

dataRej        = ft_rejectvisual(cfg,preproc);

%% Independent Component Analysis (ICA)
cfg = [ ];
cfg.method = 'runica';

comp = ft_componentanalysis(cfg, dataRej);


%% Visual inspection of the topographical disposition of the components
figure
cfg = [ ];
cfg.component = [1:14];
cfg.layout = 'biosemi64.lay';
cfg.comment = 'no';
cfg.zlim = [-3 5]; % adjust the scale
ft_topoplotIC(cfg, comp);


%% Component inspection 1 - browse whole data 
% look for a blink in the whole dataset...remember the trial!
cfg = [ ];
cfg.channel = [1 14];
ft_databrowser(cfg,dataRej);


%% Component inspection 2 - browse individual trial & component
figure;plot(comp.trial{76}(1,:)) % plot(comp.trial{X}(Y,:)) , X= trial & Y=component

figure;plot(comp.trial{88}(6,:)) % plot(comp.trial{X}(Y,:)) , X= trial & Y=component 
figure;plot(comp.trial{389}(6,:)) % plot(comp.trial{X}(Y,:)) , X= trial & Y=component 

%% Removing components
cfg = [ ];
cfg.component = [ 1 6 ];   % Components to be removed should be in between [ ]
data = ft_rejectcomponent(cfg,comp);

%% Save 'clean' data with suffix indicating component rejected version
save([ FileName '_CompRej.mat'],'data') 

