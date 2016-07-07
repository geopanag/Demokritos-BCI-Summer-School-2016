Subject = 1;
Session = 1;
Subject_Session = strcat('Sub',num2str(Subject),'_Ses',num2str(Session),'_');

ExperimentTime=48; %Total duration of the Series of trials
TrialTime = 8;%Duration of each Trial
TrainedChannels=4:17;   %The channels used for training
SampFreq=128; %Epoc sampling 
Rectime = 1;  %buffer data size (in sec)
FeatsPerChannel = 5; %the number of statistical features extracted from each channel signal
% Channels used
Channels = {'ED_COUNTER','ED_INTERPOLATED','ED_RAW_CQ','ED_AF3','ED_F7','ED_F3','ED_FC5','ED_T7','ED_P7','ED_O1','ED_O2','ED_P8','ED_T8','ED_FC6','ED_F4','ED_F8','ED_AF4','ED_GYROX','ED_GYROY','ED_TIMESTAMP','ED_ES_TIMESTAMP','ED_FUNC_ID','ED_FUNC_VALUE','ED_MARKER','ED_SYNC_SIGNAL'};

%half messages 1 (right), the other half -1 (left)
Messages=[repmat(1,ExperimentTime/(TrialTime*2),1);repmat(-1,ExperimentTime/(TrialTime*2),1)];
Messages= Messages(randperm(length(Messages)));

[EegMatrix Events Timepoint nS]  = Experiment(ExperimentTime,TrialTime,TrainedChannels,Messages,SampFreq,Rectime, Channels);


%keep only the part of the matrix filled
%the rest are redundant zeros, signifying the samples lost 
%by epoc's variable sampling
EegMatrix=EegMatrix(1:Timepoint,:);
Events=Events(1:Timepoint,:);

%check if the sampling was stable
if(ExperimentTime*SampFreq == sum(nS))
    %design bandpass filter and run it to each channel time series
    nyq=SampFreq/2;
    fLowNorm=4/nyq; % bandpass 4 to 40 Hz (theta, alpha, beta)
    fHighNorm=40/nyq;
    FilterOrder=5;
    [coef1 coef2]=butter(FilterOrder, [fLowNorm,fHighNorm],'bandpass');
    for i=1:size(EegMatrix,2)
        EegMatrix(:,i) = filter(coef1,coef2,EegMatrix(:,i));
    end;
end

%Fix the channels to act as headers
Channels = Channels(TrainedChannels);
Channels = strrep(Channels,'ED_','');

%Store the raw Signals and the Events
fid = fopen(strcat(Subject_Session,'_raw.csv'), 'w');
fprintf(fid,  strcat(strjoin(Channels,','),'\n'));
fclose(fid)

dlmwrite(strcat(Subject_Session,'_raw.csv'), EegMatrix, '-append', 'precision', '%.4f', 'delimiter', ',');

csvwrite(strcat(Subject_Session,'_events.csv'),Events);


% Feature extraction from each channel in every Trial
FeatsPerChannel = 5;
TrainData=zeros(0,FeatsPerChannel*length(TrainedChannels));

EventsIdx = find(Events~=0);
EventsIdx = [EventsIdx ; length(Events)];

previousEvent = EventsIdx(1);
for(evIdx = 2:length(EventsIdx))
    currentEvent = EventsIdx(evIdx);

    row=zeros(1,FeatsPerChannel*length(TrainedChannels)); %one epoch==>one row to be classified
    featureRange=1:FeatsPerChannel;
    
    for(channel = 1:length(TrainedChannels))
        %move the column index to the right 
        %for the features of the next channel
        if not(channel==1)
                 featureRange=((channel-1)*FeatsPerChannel+1):channel*FeatsPerChannel;
        end;
        signal = EegMatrix(previousEvent:currentEvent,channel);
        row(featureRange(1))=mean(signal);
        row(featureRange(2))=std(signal);
        row(featureRange(3))=max(signal);
        row(featureRange(4))=min(signal);
        p = hist(signal);
        row(featureRange(5))=-sum(p.*log2(p));
    end    
    
    previousEvent = currentEvent; 
    TrainData=vertcat(TrainData,row);
end

TrainData(:,size(TrainData,2)+1) = Events(find(Events~=0));

% Fix the header 
Header='';
for j=1:length(TrainedChannels)
    Header = strcat(Header,'mean',Channels(j),',std',Channels(j),',max',Channels(j),',min',Channels(j),',Entropy',Channels(j),',');
end;
Header = strcat(Header,'Labels\n');

% Store the dataset
fid = fopen(strcat(Subject_Session,'.csv'), 'w');
fprintf(fid, Header{1});
fclose(fid)

dlmwrite(strcat(Subject_Session,'.csv'), TrainData, '-append', 'precision', '%.4f', 'delimiter', ',');

