%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011 Suraj Gowda    Hong Chen                               %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function twiddle_general_4mult_draw_init_xblock(a_re, a_im, b_re, b_im, sync, ...
	    	a_re_out, a_im_out, bw_re_out, bw_im_out, sync_out, ...
            Coeffs, StepPeriod, coeffs_bram, coeff_bit_width, input_bit_width, ...
            add_latency, mult_latency, bram_latency, conv_latency, arch, use_hdl, ... 
            use_embedded, quantization, overflow)


%depends =
%{'coeff_gen_init_xblock','cmult_dsp48e_init_xblock','c_to_ri_init_xblock',
%'tap_multiply_fabric_init_xblock'}

%% diagram

b_re_del = xSignal;
b_im_del = xSignal;
w = xSignal;
w_re = xSignal;
w_im = xSignal;

mult_out1 = xSignal;
mult1_out1 = xSignal;
mult2_out1 = xSignal;
mult3_out1 = xSignal;

total_latency = mult_latency + add_latency + bram_latency + conv_latency;
% delay sync by total_latency 
sync_delay = xBlock(struct('source', 'Delay', 'name', 'sync_delay'), ...
                       struct('latency', total_latency), ...
                       {sync}, ...
                       {sync_out});

% delay a_re by total latency 
a_re_delay = xBlock(struct('source', 'Delay', 'name', 'a_re_delay'), ...
                       struct('latency', total_latency, 'reg_retiming', 'on'), {a_re}, {a_re_out});

% delay a_im by total latency 
a_im_delay = xBlock(struct('source', 'Delay', 'name', 'a_im_delay'), ...
                       struct('latency', total_latency, 'reg_retiming', 'on'), {a_im}, {a_im_out});

% delay b_re by bram_latency 
b_re_delay = xBlock(struct('source', 'Delay', 'name', 'b_re_delay'), ...
                       struct('latency', bram_latency, 'reg_retiming', 'on'), {b_re}, {b_re_del});

% delay b_im by bram_latency 
b_im_delay = xBlock(struct('source', 'Delay', 'name', 'b_im_delay'), ...
                       struct('latency', bram_latency, 'reg_retiming', 'on'), {b_im}, {b_im_del});                       

% instantiate coefficient generator
Coeffs
coeff_gen_sub = xBlock(struct('source', str2func('coeff_gen_init_xblock'), 'name', 'coeff_gen'), ...
                          {[],Coeffs, coeff_bit_width, StepPeriod, bram_latency, coeffs_bram}, ...
                          {sync}, {w});

% split w into real/imag
c_to_ri_w = xBlock(struct('source', str2func('c_to_ri_init_xblock'), 'name', 'c_to_ri_w'), ...
                            {[], ...
                            coeff_bit_width, ...
                            coeff_bit_width-2}, ...  % note this is -2
                         {w}, {w_re, w_im});
                     
mults = xBlock(struct('source', str2func('tap_multiply_fabric_init_xblock'), 'name', 'mults'), ...
	{[], input_bit_width, input_bit_width-1, coeff_bit_width, ...
	coeff_bit_width-1, 'on', 0, 0, quantization, overflow, conv_latency, ...
	4, mult_latency}, ...
	{b_re_del, w_re, b_im_del, w_im, b_im_del, w_re, b_re_del, w_im}, ...
	{mult_out1, mult1_out1, mult2_out1, mult3_out1} );


%architecture specific logic
if( strcmp(arch,'Virtex2Pro') ),
        % block: twiddles_collections/twiddle_general_4mult/convert0
        convert0_out1 = xSignal;
        convert0 = xBlock(struct('source', 'Convert', 'name', 'convert0'), ...
                                 struct('n_bits', input_bit_width+4, ...
                                        'bin_pt', input_bit_width+1, ...
                                        'quantization', quantization, ...
                                        'overflow', overflow, ...
                                        'latency', conv_latency, ...
                                        'pipeline', 'on'), ...
                                 {mult_out1}, ...
                                 {convert0_out1});

        % block: twiddles_collections/twiddle_general_4mult/convert1
        convert1_out1 = xSignal;
        convert1 = xBlock(struct('source', 'Convert', 'name', 'convert1'), ...
                                 struct('n_bits', input_bit_width+4, ...
                                        'bin_pt', input_bit_width+1, ...
                                        'quantization', quantization, ...
                                        'overflow', overflow, ...
                                        'latency', conv_latency, ...
                                        'pipeline', 'on'), ...
                                 {mult1_out1}, ...
                                 {convert1_out1});
                             
        % block: twiddles_collections/twiddle_general_4mult/convert0
        convert2_out1 = xSignal;
        convert2 = xBlock(struct('source', 'Convert', 'name', 'convert2'), ...
                                 struct('n_bits', input_bit_width+4, ...
                                        'bin_pt', input_bit_width+1, ...
                                        'quantization', quantization, ...
                                        'overflow', overflow, ...
                                        'latency', conv_latency, ...
                                        'pipeline', 'on'), ...
                                 {mult2_out1}, ...
                                 {convert2_out1});

        % block: twiddles_collections/twiddle_general_4mult/convert1
        %convert3_out1 = xSignal;
        convert3 = xBlock(struct('source', 'Convert', 'name', 'convert3'), ...
                                 struct('n_bits', input_bit_width+4, ...
                                        'bin_pt', input_bit_width+1, ...
                                        'quantization', quantization, ...
                                        'overflow', overflow, ...
                                        'latency', conv_latency, ...
                                        'pipeline', 'on'), ...
                                 {mult3_out1}, ...
                                 {convert3_out1});
                             
        % block: twiddles_collections/twiddle_general_4mult/AddSub
        %AddSub_out1 = xSignal;
        AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
                               struct('mode', 'Subtraction', ...
                                      'latency', add_latency, ...
                                      'use_behavioral_HDL', 'on'), ...
                               {convert0_out1, convert1_out1}, ...
                               {bw_re_out});

        % block: twiddles_collections/twiddle_general_4mult/AddSub1
        %AddSub1_out1 = xSignal;
        AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
                                struct('latency', add_latency, ...
                                       'use_behavioral_HDL', 'on'), ...
                                {convert2_out1, convert3_out1}, ...
                                {bw_im_out});
                            
elseif( strcmp(arch,'Virtex5') )     
        % block: twiddles_collections/twiddle_general_4mult/AddSub
        AddSub_out1 = xSignal;
        AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
                               struct('mode', 'Subtraction', ...
                                      'latency', add_latency, ...
                                      'use_behavioral_HDL', 'on'), ...
                               {mult_out1, mult1_out1}, ...
                               {AddSub_out1});

        % block: twiddles_collections/twiddle_general_4mult/AddSub1
        AddSub1_out1 = xSignal;
        AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
                                struct('latency', add_latency, ...
                                       'use_behavioral_HDL', 'on'), ...
                                {mult2_out1, mult3_out1}, ...
                                {AddSub1_out1});
                            
        % block: twiddles_collections/twiddle_general_4mult/convert0
        %convert0_out1 = xSignal;
        convert0 = xBlock(struct('source', 'Convert', 'name', 'convert0'), ...
                                 struct('n_bits', input_bit_width+4, ...
                                        'bin_pt', input_bit_width+1, ...
                                        'quantization', quantization, ...
                                        'overflow', overflow, ...
                                        'latency', conv_latency, ...
                                        'pipeline', 'on'), ...
                                 {AddSub_out1}, ...
                                 {bw_re_out});

        % block: twiddles_collections/twiddle_general_4mult/convert1
        %convert1_out1 = xSignal;
        convert1 = xBlock(struct('source', 'Convert', 'name', 'convert1'), ...
                                 struct('n_bits', input_bit_width+4, ...
                                        'bin_pt', input_bit_width+1, ...
                                        'quantization', quantization, ...
                                        'overflow', overflow, ...
                                        'latency', conv_latency, ...
                                        'pipeline', 'on'), ...
                                 {AddSub1_out1}, ...
                                 {bw_im_out});
end
            
                      
end                      
                      
                      
