%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   Center for Astronomy Signal Processing and Electronics Research           %
%   http://casper.berkeley.edu                                                %      
%   Copyright (C) 2011    Hong Chen                                           %
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
function [dependlist, tree] = get_dependlist(blk_name, varargin)


numvarargs = length(varargin);
if numvarargs > 0 && isnumeric(varargin{1})
    depth = varargin{1};
    varargin = varargin(2:end);
    if numvarargs > 1 && ischar(varargin{1}) 
        temp_var = varargin{1};
        if ~strcmp(temp_var(1), '-')
            tree_prev_branch = varargin{1};
        else
            tree_prev_branch = blk_name;
        end
    end
else
    depth = 0;
    tree_prev_branch = blk_name;
end

tree = {tree_prev_branch};


if ismember('-verbose', varargin)
    if ismember('-recursive', varargin) && ~ismember('-super', varargin)
        disp(' ');
        disp('Recursively searching for sub-blocks...');
        disp(['current block: ', blk_name]);
        disp(['current depth: ', num2str(depth)]);
        disp(['previous branch: ', tree_prev_branch]);
        disp(' ');
        disp('--------------');
    elseif ismember('-recursive', varargin) && ismember('-super', varargin)
        disp(' ');
        disp('Recursively searching for super-blocks...');
        disp(['current block: ', blk_name]);
        disp(['current depth: ', num2str(depth)]);
        disp(['previous branch: ', tree_prev_branch]);
        disp(' ');
        disp('--------------');
    else
        disp('***********************************************************************');
        disp('get_depndlist():');
        disp('---- Running with blk_name only:');
        disp('     default depth = 0');
        disp('     get all subblocks of the target block (down to any level)');
        disp('     return a cell array of the _init_xblock.m files of those blocks');
        disp('---- Running with extra parameter ''-super'' (and without ''-recursive''): ');
        disp('     get all blocks that *directly* depend on the target block');
        disp('     return a cell array of the _init_xblock.m files of those blocks');
        disp('---- Running with extra parameter ''-super'' and ''-recursive'': ');
        disp('     get all blocks that *directly* and *indirectly* depend on the target block');
        disp('     return a cell array of the _init_xblock.m files of those blocks');
        disp(' ');
        disp('See also: add_to_subblk_list(), rm_from_subblk_list(), rename_blk()');
        disp(' ');
        disp('Block hierarchy information stored in file subblk_list.mat');
        disp('***********************************************************************');
    end
end


if isempty(varargin) || ~ismember('-super', varargin)
    subblk_list = load('subblk_list',[blk_name,'_subblk_list']);

    if ~isempty(fieldnames(subblk_list))
        subblocks = subblk_list.([blk_name,'_subblk_list']);
    else
        subblocks = {};
    end

    dependlist = {strcat(blk_name,'_init_xblock')};
    for i = 1:length(subblocks)
        if ismember('-verbose', varargin)
            [temp_list, tree_updated_branch] = get_dependlist(subblocks{i}, depth+1, [tree_prev_branch,' <-- ', subblocks{i}], '-verbose', '-recursive');
        else
            [temp_list, tree_updated_branch] = get_dependlist(subblocks{i}, depth+1, [tree_prev_branch,' <-- ', subblocks{i}], '-recursive');
        end
        dependlist = [dependlist, temp_list{:}];
        dependlist = unique(dependlist);
        tree = [tree, {tree_updated_branch}];
    end

    dependlist = unique(dependlist);
elseif ismember('-super', varargin) && ismember('-recursive', varargin)
    recorded_subblk_names = who('-file','subblk_list.mat');
    recorded_subblk_lists = cell(1,length(recorded_subblk_names));
    super_blk_names = {};
    
    for i=1:length(recorded_subblk_names)
        recorded_subblk_lists{i} = load('subblk_list',recorded_subblk_names{i});
        
        if ismember(blk_name,recorded_subblk_lists{i}.(recorded_subblk_names{i}))
            super_blk_name_idx = findstr(recorded_subblk_names{i},'_subblk_list');
            super_blk_name = recorded_subblk_names{i}(1:super_blk_name_idx-1);
            if ismember('-verbose', varargin)
                [super_super_blk_names, tree_updated_branch] = get_dependlist(super_blk_name, depth-1, [tree_prev_branch, ' --> ', super_blk_name], '-super', '-verbose', '-recursive');
            else
                [super_super_blk_names, tree_updated_branch] = get_dependlist(super_blk_name, depth-1, [tree_prev_branch, ' --> ', super_blk_name], '-super', '-recursive');
            end
            super_blk_names = [super_blk_names, super_super_blk_names, {[super_blk_name,'_init_xblock']}];
            super_blk_names = unique(super_blk_names);
            tree = [tree, {tree_updated_branch}];
        end
    end
    
    dependlist =super_blk_names;
elseif ismember('-super', varargin) && ~ismember('-recursive', varargin)
    recorded_subblk_names = who('-file','subblk_list.mat');
    recorded_subblk_lists = cell(1,length(recorded_subblk_names));
    super_blk_names = {};
    
    for i=1:length(recorded_subblk_names)
        recorded_subblk_lists{i} = load('subblk_list',recorded_subblk_names{i});
        
        if ismember(blk_name,recorded_subblk_lists{i}.(recorded_subblk_names{i}))
            super_blk_name_idx = findstr(recorded_subblk_names{i},'_subblk_list'); 
            super_blk_name = recorded_subblk_names{i}(1:super_blk_name_idx-1);
            super_blk_names = [super_blk_names,{[super_blk_name,'_init_xblock']}];
            tree = [tree, {[tree_prev_branch, ' --> ', super_blk_name]}];
        end
    end
    
    dependlist =super_blk_names;
end

if ismember('-verbose', varargin) && depth ==0
    disp('------long version------');
    plot_tree(tree);
    disp('------------------------');
    disp('-----short version------');
    plot_tree_short(tree); 
    disp('------------------------');
    disp('--------list------------');
    plot_list(dependlist);
    disp('------------------------');
end

end

function plot_list(blk_list)
    for i=1:length(blk_list)
        disp(blk_list{i});
    end
end

function plot_tree(tree)
    if iscell(tree)
        len_tree = length(tree);
        for i = 1:len_tree
            plot_tree(tree{i});
        end
    else
        disp(tree);
    end
end

function plot_tree_short(tree)
    if iscell(tree)
        len_tree = length(tree);
        if len_tree <= 2
            plot_tree_short(tree{len_tree});
        else
            for i=2:len_tree
                plot_tree_short(tree{i});
            end
        end
    else
        disp(tree);
    end
end