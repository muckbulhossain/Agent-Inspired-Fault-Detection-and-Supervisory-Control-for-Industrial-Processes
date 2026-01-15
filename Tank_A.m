function Tank_A(block)
% Level-2 MATLAB S-Function for Tank A
    setup(block);
end

function setup(block)
    % One vector input: [C_LAC_T; C_N_T; C_MEV_T; Q_T; Q_OUT]
    block.NumInputPorts  = 1;
    block.NumOutputPorts = 1;

    % Input port
    block.InputPort(1).Dimensions         = 5;
    block.InputPort(1).DatatypeID         = 0;      % double
    block.InputPort(1).Complexity         = 'Real';
    block.InputPort(1).DirectFeedthrough  = false;

    % Output port: [V; C_LAC; C_N; C_MEV]
    block.OutputPort(1).Dimensions        = 4;
    block.OutputPort(1).DatatypeID        = 0;
    block.OutputPort(1).Complexity        = 'Real';

    % States
    block.NumContStates = 4;
    block.NumDialogPrms = 0;

    % Continuous sample time
    block.SampleTimes = [0 0];

    block.SimStateCompliance = 'DefaultSimState';

    % Methods
    block.RegBlockMethod('InitializeConditions', @InitConditions);
    block.RegBlockMethod('Derivatives',          @Derivatives);
    block.RegBlockMethod('Outputs',              @Outputs);
end

function InitConditions(block)
    % Initial states: [V; C_LAC; C_N; C_MEV]
    block.ContStates.Data = [1000; ...
                             14.8096563646109; ...
                             2.51553709810012; ...
                             1.2];
end

function Derivatives(block)
    x = block.ContStates.Data;   % [V; C_LAC; C_N; C_MEV]
    u = block.InputPort(1).Data; % [C_LAC_T; C_N_T; C_MEV_T; Q_T; Q_OUT]

    V          = x(1);
    C_LAC_tank = x(2);
    C_N_tank   = x(3);
    C_MEV_tank = x(4);

    C_LAC_T = u(1);
    C_N_T   = u(2);
    C_MEV_T = u(3);
    Q_T     = u(4);
    Q_OUT   = u(5);

    dVdt      = Q_T - Q_OUT;
    dC_LAC_dt = (C_LAC_T*Q_T - C_LAC_tank*Q_OUT - C_LAC_tank*(Q_T - Q_OUT)) / V;
    dC_N_dt   = (C_N_T*Q_T   - C_N_tank*Q_OUT   - C_N_tank*(Q_T - Q_OUT))   / V;
    dC_MEV_dt = (C_MEV_T*Q_T - C_MEV_tank*Q_OUT - C_MEV_tank*(Q_T - Q_OUT)) / V;

    block.Derivatives.Data = [dVdt; dC_LAC_dt; dC_N_dt; dC_MEV_dt];
end

function Outputs(block)
    x = block.ContStates.Data;
    block.OutputPort(1).Data = x;   % [V; C_LAC; C_N; C_MEV]
end
