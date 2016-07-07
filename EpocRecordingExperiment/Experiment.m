function [EegMatrix Events Timepoint nS]= Experiment(ExperimentTime, TrialTime,TrainedChannels,Messages,SampFreq,Rectime, Channels)

    EegMatrix = zeros(ExperimentTime*SampFreq,length(TrainedChannels));
    nS = zeros(ExperimentTime*SampFreq,1); %the number of samples acquired 
    
    %%
    
    Channels_enum=struct('ED_COUNTER',0,'ED_INTERPOLATED',1,'ED_RAW_CQ',2,'ED_AF3',3,'ED_F7',4,'ED_F3',5,'ED_FC5',6,'ED_T7',7,'ED_P7',8,'ED_O1',9,'ED_O2',10,'ED_P8',11,'ED_T8',12,'ED_FC6',13,'ED_F4',14,'ED_F8',15,'ED_AF4',16,'ED_GYROX',17,'ED_GYROY',18,'ED_TIMESTAMP',19,'ED_ES_TIMESTAMP',20,'ED_FUNC_ID',21,'ED_FUNC_VALUE',22,'ED_MARKER',23,'ED_SYNC_SIGNAL',24);
    lib_flag_popup = 1;

    %%
    % Check to see if library was already loaded
    if ~libisloaded('edk')    
        [nf, w] = loadlibrary('edk','edk',  'addheader', 'EmoStateDLL', 'addheader', 'edkErrorCode'); 
        disp(['EDK library loaded']);
        if( lib_flag_popup )
            libfunctionsview('edk')
            nf % these should be empty if all went well
            w
        end
    else
        disp(['EDK library already loaded']);
    end

    %%
    %Connect with emoEngine (emotiv's epoc api)
    AllOK = calllib('edk','EE_EngineConnect','Emotiv Systems-5'); % success means this value is 0
    if (not(AllOK==0))
       msgbox('Something is wrong with the connection of EPOC') 
    end
    
    hData = calllib('edk','EE_DataCreate');
    calllib('edk','EE_DataSetBufferSizeInSec',Rectime);
    eEvent = calllib('edk','EE_EmoEngineEventCreate');
    readytocollect = false;


   
    %%

    Events=zeros(ExperimentTime*SampFreq,1);
    Index=1;
    
	%timepoint resemples the time index of the recording in EegMatrix
	%it can't get bigger than ExperimentTime*SampFreq
    Timepoint=0;
    Exper = tic; 
    RelaxHandle = nan;
    while(toc(Exper) < ExperimentTime)
        if(ishandle(RelaxHandle))
            delete(RelaxHandle)
        end
		%Change the stimuli here
        Trial = tic; 
		%ShowImage(Messages(Index))
        if(Messages(Index)>0)
            MoveHandle = msgbox('Right');
        else
            MoveHandle = msgbox('Left');
        end;
        
        %keep a vector of events with the same timepoint as the EEG recording
        %to correspond the EEG activity with each event
        Events(Timepoint+1)=Messages(Index);
        
        while(toc(Trial) < TrialTime)
            %check if you can collect
            state = calllib('edk','EE_EngineGetNextEvent',eEvent); % state = 0 if everything's OK
            eventType = calllib('edk','EE_EmoEngineEventGetType',eEvent);
            userID=libpointer('uint32Ptr',0);

            if strcmp(eventType,'EE_UserAdded') == true
                userID_value = get(userID,'value');
                calllib('edk','EE_DataAcquisitionEnable',userID_value,true);
                readytocollect = true;
            end

            %collect the data from dongle
            if (readytocollect) 
                calllib('edk','EE_DataUpdateHandle', 0, hData);
                nSamples = libpointer('uint32Ptr',0);
                calllib('edk','EE_DataGetNumberOfSample',hData,nSamples);
                nSamplesTaken = get(nSamples,'value') ;
                
                if (nSamplesTaken ~= 0)
                    data = libpointer('doublePtr',zeros(1,nSamplesTaken));
                        %take the specified channels used for training
                        for (i = TrainedChannels)
                            calllib('edk','EE_DataGet',hData, Channels_enum.(char(Channels(i))), data, uint32(nSamplesTaken));
                            DataValue = get(data,'value'); 
                            %store the data in EegMatrix
                            EegMatrix(Timepoint+1:Timepoint+length(DataValue),i-3) = DataValue;                    
                        end	  
                        
                        EegMatrix(Timepoint+1:Timepoint+length(DataValue),i-3) = DataValue;  
                        %update timepoint for the next store in EegMatrix
                        nS(Timepoint+1) = nSamplesTaken;
                        Timepoint = Timepoint + length(DataValue);
                end
                
            end
            
            if(toc(Trial)>(TrialTime-4)) %rest for 4 sec
                if ishandle(MoveHandle)
                    delete(MoveHandle);
                    RelaxHandle = msgbox('RELAX');
                end
            end
        end
        Index=Index+1;
    end
    
    if(ishandle(RelaxHandle))
            delete(RelaxHandle)
    end
    calllib('edk','EE_EngineDisconnect');
    
end