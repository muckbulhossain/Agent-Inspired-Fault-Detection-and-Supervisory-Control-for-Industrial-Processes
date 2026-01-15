function CSTR(block)
% Level-2 MATLAB S-Function for CSTR
    setup(block);
end

function setup(block)
    % One vector input: [C_X_F; C_LAC_F; C_N_F; C_MEV_F; Q_IN; Q_OUT]
    block.NumInputPorts  = 1;
    block.NumOutputPorts = 1;

    block.InputPort(1).Dimensions  = 6;
    block.InputPort(1).DatatypeID  = 0;
    block.InputPort(1).Complexity  = 'Real';
    block.InputPort(1).DirectFeedthrough = false;

    % Outputs: [V; C_X_S; C_LAC_S; C_N_S; C_MEV_S; h]
    block.OutputPort(1).Dimensions = 6;
    block.OutputPort(1).DatatypeID = 0;
    block.OutputPort(1).Complexity = 'Real';

    block.NumContStates = 5;
    block.NumDialogPrms = 0;

    block.SampleTimes = [0 0];

    block.SimStateCompliance = 'DefaultSimState';

    block.RegBlockMethod('InitializeConditions', @InitConditions);
    block.RegBlockMethod('Derivatives',          @Derivatives);
    block.RegBlockMethod('Outputs',              @Outputs);
end

function InitConditions(block)
    % Initial states: [V; C_X_S; C_LAC_S; C_N_S; C_MEV_S]
    block.ContStates.Data = [5000; ...
                             106.351163614666; ...
                             14.8096563646109; ...
                             2.51553709810012; ...
                             1.20000000000003];
end

function Derivatives(block)
    x = block.ContStates.Data;   % [V; C_X_S; C_LAC_S; C_N_S; C_MEV_S]
    u = block.InputPort(1).Data; % [C_X_F; C_LAC_F; C_N_F; C_MEV_F; Q_IN; Q_OUT]

    % States
    V       = x(1);
    C_X_S   = x(2);
    C_LAC_S = x(3);
    C_N_S   = x(4);
    C_MEV_S = x(5);

    % Inputs
    C_X_F   = u(1);
    C_LAC_F = u(2);
    C_N_F   = u(3);
    C_MEV_F = u(4);
    Q_IN    = u(5);
    Q_OUT   = u(6);

    % Parameters
    mu_max   = 0.120;
    q_max_MEV = 1.9e-4;
    K_MEV    = 5.42e-6;
    Y_X_LAC  = 0.483;
    Y_X_N    = 20.06;
    Y_MEV_LAC = 7.06e-4;
    K_LAC    = 1.63;
    K_N      = 8.84e-2;
    K_LAC_MEV = 13.23;
    K_I_N    = 0.158;
    K_I_N_MEV = 9.65e-2;

    mu_1 = mu_max * C_LAC_S/(C_LAC_S + K_LAC*C_X_S) * C_N_S/(C_N_S + K_N*C_X_S);
    Y_LAC_X  = 1/Y_X_LAC;

    mu_2 = mu_max * C_LAC_S/(C_LAC_S + K_LAC*C_X_S) * ...
           C_N_S/(C_N_S + K_N*C_X_S) * K_I_N/(K_I_N + C_N_S);
    Y_LAC_MEV = 1/Y_MEV_LAC;

    mu_3 = q_max_MEV * C_LAC_S/(C_LAC_S + K_LAC_MEV*C_X_S) * ...
           K_I_N_MEV/(K_I_N_MEV + C_N_S);
    Y_N_X = 1/Y_X_N;

    dVdt        = Q_IN - Q_OUT;
    dC_X_Sdt    = mu_1*C_X_S + (Q_IN*C_X_F   - Q_OUT*C_X_S   - C_X_S*(Q_IN - Q_OUT))/V;
    dC_LAC_Sdt  = (-Y_LAC_X*mu_2 - Y_LAC_MEV*mu_3)*C_X_S + ...
                  (Q_IN*C_LAC_F - Q_OUT*C_LAC_S - C_LAC_S*(Q_IN - Q_OUT))/V;
    dC_N_Sdt    = (-Y_N_X*mu_1)*C_X_S + ...
                  (Q_IN*C_N_F   - Q_OUT*C_N_S   - C_N_S*(Q_IN - Q_OUT))/V;
    dC_MEV_Sdt  = (mu_3 + K_MEV*C_LAC_S)*C_X_S + ...
                  (Q_IN*C_MEV_F - Q_OUT*C_MEV_S - C_MEV_S*(Q_IN - Q_OUT))/V;

    block.Derivatives.Data = [dVdt; dC_X_Sdt; dC_LAC_Sdt; dC_N_Sdt; dC_MEV_Sdt];
end

function Outputs(block)
    x = block.ContStates.Data;   % [V; C_X_S; C_LAC_S; C_N_S; C_MEV_S]

    d = 0.9;                     % reactor diameter (m)
    A = pi/4*d^2;                % cross-sectional area (m^2)
    h = (x(1)/1000)/A;           % liquid height (m), V in L

    block.OutputPort(1).Data = [x; h];
end
