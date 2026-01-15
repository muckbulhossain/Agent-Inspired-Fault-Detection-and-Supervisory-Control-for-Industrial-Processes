clear; clc;


modelName = 'KTB1_F';
bridgeBlockName = 'Faultbridge';
outputBlockName = 'AI_Prediction_Input'; % LIVE Prediction

% --- STEP 1: AUTO-DECLARE BLOCKS ---
if ~bdIsLoaded(modelName), load_system(modelName); end

blocks = {
    'AI_Lactose_Actuator', 'ClacS'; 
    'AI_Adenine_Actuator', 'CnS';
    'Soft_Lactose_Value',  'AI_Lactose_Actuator'; 
    'Soft_Adenine_Value',  'AI_Adenine_Actuator';
    'FaultID_locked',      'AI_Prediction_Input' 
};

for i = 1:size(blocks, 1)
    blkName = blocks{i, 1};
    refBlock = blocks{i, 2};
    fullPath = [modelName '/' blkName];
    
    try
        get_param(fullPath, 'Handle');
    catch
        fprintf('[SETUP] Creating missing block: %s\n', blkName);
        try
            refPos = get_param([modelName '/' refBlock], 'Position');
            newPos = refPos + [0, 60, 0, 60]; 
            add_block('built-in/Constant', fullPath, 'Position', newPos);
            set_param(fullPath, 'Value', '0');
        catch
            fprintf('[WARN] Ref %s not found.\n', refBlock);
        end
    end
end

% --- STEP 2: MQTT SETUP ---
try
    mqClient = mqttclient('tcp://localhost', Port=1883);
    subscribe(mqClient, 'fault_detection/live/prediction');
    subscribe(mqClient, 'fault_detection/live/control'); 
    subscribe(mqClient, 'fault_detection/live/soft_sensor'); 
    disp('[MQTT] Connected.');
catch
    disp('[ERR] MQTT Failed.'); return;
end

% --- STEP 3: START SIMULATION ---
set_param(modelName, 'SimulationCommand', 'start');
pause(1);

while strcmpi(get_param(modelName, 'SimulationStatus'), 'running')
    try
        % A. SEND FEATURES
        rto = get_param([modelName '/' bridgeBlockName], 'RuntimeObject');
        if ~isempty(rto)
            data = rto.InputPort(2).Data;
            payload.Time = rto.InputPort(1).Data;
            payload.features = struct();
            for i = 1:length(data)
                payload.features.(sprintf('Data_%d',i)) = data(i);
            end
            write(mqClient, 'fault_detection/live/features', jsonencode(payload));
        end

        % B. READ MESSAGES
        if mqClient.Connected
            msgTable = read(mqClient); 
            if ~isempty(msgTable)
                
                % 1. Handle Predictions 
                predRows = strcmp(msgTable.Topic, 'fault_detection/live/prediction');
                if any(predRows)
                    latest = jsondecode(msgTable(predRows,:).Data{end});
                    
                    % Update LIVE Prediction 
                    set_param([modelName '/' outputBlockName], 'Value', num2str(latest.fault_id));
                    
                    % Update LOCKED Decision 
                    if isfield(latest, 'locked_id')
                        set_param([modelName '/FaultID_locked'], 'Value', num2str(latest.locked_id));
                    end
                end
                
                % 2. Exponentially Weighted Moving Average Filter(Soft sensor)
                softRows = strcmp(msgTable.Topic, 'fault_detection/live/soft_sensor');
                if any(softRows)
                    softData = jsondecode(msgTable(softRows,:).Data{end});
                    set_param([modelName '/Soft_Lactose_Value'], 'Value', num2str(softData.soft_lactose));
                    set_param([modelName '/Soft_Adenine_Value'], 'Value', num2str(softData.soft_adenine));
                end

                % 3. Control
                ctrlMsgs = msgTable(strcmp(msgTable.Topic, 'fault_detection/live/control'), :);
                if ~isempty(ctrlMsgs)
                    for k = 1:height(ctrlMsgs)
                         cmd = jsondecode(ctrlMsgs.Data{k});
                         target = cmd.target_block;
                         val = cmd.value;
                         try
                             set_param([modelName '/' target], 'Value', val);
                         catch
                         end
                    end
                end
            end
        end
        pause(0.1); 
    catch
    end
end
disp('[INFO] Simulation Stopped.');