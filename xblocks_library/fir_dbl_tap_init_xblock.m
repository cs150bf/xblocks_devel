%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen                                           %
%   Copyright (C) 2007 Terry Filiba, Aaron Parsons                            %
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
function fir_dbl_tap_init_xblock(blk, factor, add_latency, mult_latency, coeff_bit_width, coeff_bin_pt)



%% inports
xlsub2_a = xInport('a');
xlsub2_b = xInport('b');
xlsub2_c = xInport('c');
xlsub2_d = xInport('d');

%% outports
xlsub2_a_out = xOutport('a_out');
xlsub2_b_out = xOutport('b_out');
xlsub2_c_out = xOutport('c_out');
xlsub2_d_out = xOutport('d_out');
xlsub2_real = xOutport('real');
xlsub2_imag = xOutport('imag');

%% diagram

% block: fir_dbl_mdl/fir_dbl_tap/AddSub
xlsub2_AddSub_out1 = xSignal;
xlsub2_AddSub = xBlock(struct('source', 'AddSub', 'name', 'AddSub'), ...
                       struct('latency', add_latency, ...
                              'arith_type', 'Signed  (2''s comp)', ...
                              'n_bits', 18, ...
                              'bin_pt', 16, ...
                              'use_behavioral_HDL', 'on', ...
                              'use_rpm', 'on'), ...
                       {xlsub2_a, xlsub2_c}, ...
                       {xlsub2_AddSub_out1});

% block: fir_dbl_mdl/fir_dbl_tap/AddSub1
xlsub2_AddSub1_out1 = xSignal;
xlsub2_AddSub1 = xBlock(struct('source', 'AddSub', 'name', 'AddSub1'), ...
                        struct('latency', add_latency, ...
                               'arith_type', 'Signed  (2''s comp)', ...
                               'n_bits', 18, ...
                               'bin_pt', 16, ...
                               'use_behavioral_HDL', 'on', ...
                               'use_rpm', 'on'), ...
                        {xlsub2_b, xlsub2_d}, ...
                        {xlsub2_AddSub1_out1});

% block: fir_dbl_mdl/fir_dbl_tap/Mult
xlsub2_coefficient_out1 = xSignal;
xlsub2_Mult = xBlock(struct('source', 'Mult', 'name', 'Mult'), ...
                     struct('n_bits', 18, ...
                            'bin_pt', 17, ...
                            'latency', mult_latency, ...
                            'use_behavioral_HDL', 'on', ...
                            'use_rpm', 'off', ...
                            'placement_style', 'Rectangular shape'), ...
                     {xlsub2_coefficient_out1, xlsub2_AddSub1_out1}, ...
                     {xlsub2_imag});

% block: fir_dbl_mdl/fir_dbl_tap/Mult1
xlsub2_Mult1 = xBlock(struct('source', 'Mult', 'name', 'Mult1'), ...
                      struct('n_bits', 18, ...
                             'bin_pt', 17, ...
                             'latency', mult_latency, ...
                             'use_behavioral_HDL', 'on', ...
                             'use_rpm', 'off', ...
                             'placement_style', 'Rectangular shape'), ...
                      {xlsub2_coefficient_out1, xlsub2_AddSub_out1}, ...
                      {xlsub2_real});

% block: fir_dbl_mdl/fir_dbl_tap/Register
xlsub2_Register = xBlock(struct('source', 'Register', 'name', 'Register'), ...
                         [], ...
                         {xlsub2_a}, ...
                         {xlsub2_a_out});

% block: fir_dbl_mdl/fir_dbl_tap/Register1
xlsub2_Register1 = xBlock(struct('source', 'Register', 'name', 'Register1'), ...
                          [], ...
                          {xlsub2_b}, ...
                          {xlsub2_b_out});

% block: fir_dbl_mdl/fir_dbl_tap/Register2
xlsub2_Register2 = xBlock(struct('source', 'Register', 'name', 'Register2'), ...
                          [], ...
                          {xlsub2_c}, ...
                          {xlsub2_c_out});

% block: fir_dbl_mdl/fir_dbl_tap/Register3
xlsub2_Register3 = xBlock(struct('source', 'Register', 'name', 'Register3'), ...
                          [], ...
                          {xlsub2_d}, ...
                          {xlsub2_d_out});

% block: fir_dbl_mdl/fir_dbl_tap/coefficient
xlsub2_coefficient = xBlock(struct('source', 'Constant', 'name', 'coefficient'), ...
                            struct('const', factor, ...
                                   'n_bits', coeff_bit_width, ...
                                   'bin_pt', coeff_bin_pt, ...
                                   'explicit_period', 'on'), ...
                            {}, ...
                            {xlsub2_coefficient_out1});


if ~isempty(blk) && ~strcmp(blk(1),'/')
    clean_blocks(blk);
end

end

