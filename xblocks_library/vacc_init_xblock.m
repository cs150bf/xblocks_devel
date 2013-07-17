function vacc_init_xblock(varargin)
% TODO: reg retiming

defaults = { ...
	'veclen', 5, ...
	'n_inputs', 1, ...
	'max_accum', 5, ...
	'arith_type', 0, ...
	'in_bit_width', 18, ...
	'in_bin_pt', 17, ...
	'out_bit_width', 32, ...
	'out_bin_pt', 17, ...
	'register_din', 0, ...
	'add_latency', 2, ...
	'bram_latency', 2, ...
	'mux_latency', 0, ...
	'use_dsp48', 1, ...
};

veclen = get_var('veclen', 'defaults', defaults, varargin{:});
n_inputs = get_var('n_inputs', 'defaults', defaults, varargin{:});
max_accum = get_var('max_accum', 'defaults', defaults, varargin{:});
arith_type = get_var('arith_type', 'defaults', defaults, varargin{:});
in_bit_width = get_var('in_bit_width', 'defaults', defaults, varargin{:});
in_bin_pt = get_var('in_bin_pt', 'defaults', defaults, varargin{:});
out_bit_width = get_var('out_bit_width', 'defaults', defaults, varargin{:});
out_bin_pt = get_var('out_bin_pt', 'defaults', defaults, varargin{:});
register_din = get_var('register_din', 'defaults', defaults, varargin{:});
add_latency = get_var('add_latency', 'defaults', defaults, varargin{:});
bram_latency = get_var('bram_latency', 'defaults', defaults, varargin{:});
mux_latency = get_var('mux_latency', 'defaults', defaults, varargin{:});
use_dsp48 = get_var('use_dsp48', 'defaults', defaults, varargin{:});

if use_dsp48,
    warning('vacc_init_xblock: using DSP48, so ignoring mux latency');
    mux_latency = 0;
end

%% inports
sync = xInport('sync');
acc_len = xInport('acc_len');
din = xblock_new_inputs('din', n_inputs, 1);

%% outports
valid = xOutport('valid');
dout = xblock_new_outputs('dout', n_inputs, 1);

%% diagram

din_del = xblock_new_bus( n_inputs, 1);
xblock_delay( din, din_del, 'din', mux_latency+1, 'Register' );

if veclen < 3,
    errordlg('Vector Accumulator: Vector Length must be >= 2^3')
end
in_int_bits = in_bit_width - in_bin_pt;
out_int_bits = out_bit_width - out_bin_pt;

actual_veclen = 2^veclen;

if register_din,
    reg_retiming = 'on';
else
    reg_retiming = 'off';
end



% block: untitled1/vacc_init_xblock/AND
ValidCompare_out1 = xSignal;
SyncCompare_out1 = xSignal;
AND_out1 = xSignal;
AND = xBlock(struct('source', 'Logical', 'name', 'AND'), ...
                    struct('n_bits', 8, ...
                           'bin_pt', 2), ...
                    {ValidCompare_out1, SyncCompare_out1}, ...
                    {AND_out1});

% block: untitled1/vacc_init_xblock/AccEnCompare
Slice_out1 = xSignal;
Zero_out1 = xSignal;
AccEnCompare_out1 = xSignal;
AccEnCompare = xBlock(struct('source', 'Relational', 'name', 'AccEnCompare'), ...
                             struct('mode', 'a!=b', 'latency', 1), ...
                             {Slice_out1, Zero_out1}, ...
                             {AccEnCompare_out1});

% block: untitled1/vacc_init_xblock/Counter
OR_out1 = xSignal;
Counter_out1 = xSignal;
Counter = xBlock(struct('source', 'Counter', 'name', 'Counter'), ...
                        struct('n_bits', max_accum + veclen, ...
                               'rst', 'on', ...
                               'use_rpm', 'on'), ...
                        {OR_out1}, ...
                        {Counter_out1});



% block: untitled1/vacc_init_xblock/OR
SyncDelay_out1 = xSignal;
OR = xBlock(struct('source', 'Logical', 'name', 'OR'), ...
                   struct('logical_function', 'OR', ...
                          'n_bits', 8, ...
                          'bin_pt', 2), ...
                   {sync, AND_out1}, ...
                   {OR_out1});

% block: untitled1/vacc_init_xblock/Slice
Slice = xBlock(struct('source', 'Slice', 'name', 'Slice'), ...
                      struct('nbits', max_accum), ...
                      {Counter_out1}, ...
                      {Slice_out1});

% block: untitled1/vacc_init_xblock/SliceLow
SliceLow_out1 = xSignal;
SliceLow = xBlock(struct('source', 'Slice', 'name', 'SliceLow'), ...
                         struct('nbits', veclen, ...
                                'mode', 'Lower Bit Location + Width'), ...
                         {Counter_out1}, ...
                         {SliceLow_out1});


% block: untitled1/vacc_init_xblock/SyncCompare
SyncConst_out1 = xSignal;
SyncCompare = xBlock(struct('source', 'Relational', 'name', 'SyncCompare'), ...
                            struct('latency', 1), ...
                            {SliceLow_out1, SyncConst_out1}, ...
                            {SyncCompare_out1});

% block: untitled1/vacc_init_xblock/SyncConst
SyncConst = xBlock(struct('source', 'Constant', 'name', 'SyncConst'), ...
                          struct('arith_type', 'Unsigned', ...
                                 'const', actual_veclen-2, ...
                                 'n_bits', veclen, ...
                                 'bin_pt', 0, ...
                                 'explicit_period', 'on'), ...
                          {}, ...
                          {SyncConst_out1});


% block: untitled1/vacc_init_xblock/ValidCompare
ValidCompare = xBlock(struct('source', 'Relational', 'name', 'ValidCompare'), ...
                             struct('latency', 1), ...
                             {acc_len, Slice_out1}, ...
                             {ValidCompare_out1});

% block: untitled1/vacc_init_xblock/ValidDelay
ValidDelay = xBlock(struct('source', 'Delay', 'name', 'ValidDelay'), ...
                           struct('latency', add_latency+mux_latency), ...
                           {ValidCompare_out1}, ...
                           {valid});

% block: untitled1/vacc_init_xblock/Zero
Zero = xBlock(struct('source', 'Constant', 'name', 'Zero'), ...
                     struct('arith_type', 'Unsigned', ...
                            'const', 0, ...
                            'n_bits', 8, ...
                            'bin_pt', 0, ...
                            'explicit_period', 'on'), ...
                     {}, ...
                     {Zero_out1});


 vacc_core_config.source = str2func('vacc_core_init_xblock');
 vacc_core_config.name = 'vacc_core';
 %%% TODO: pass down mux_latency properly
 vacc_core_params = {'veclen', actual_veclen, 'n_inputs', n_inputs, 'arith_type', arith_type, ...
     'bit_width_out', out_bit_width, 'bin_pt_out', out_bin_pt, ...
     'add_latency', add_latency, 'bram_latency', bram_latency, ...
     'mux_latency', 0, 'bin_pt_in', in_bin_pt, 'bin_pt_out', out_bin_pt, ...
     'use_dsp48', use_dsp48 };
 xBlock(vacc_core_config, vacc_core_params, {din_del{:,1}, AccEnCompare_out1}, {dout{:,1}} );


