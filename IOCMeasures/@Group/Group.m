classdef Group < Task
    %GROUP A group of tasks; this one just runs them sequentially
    %   Subclasses pick which task to run among several, and in which
    %   order, one at a time (for each call to runTask()).  You may nest
    %   a group of tasks inside another group (ex. a staircase in a group
    %   of staircases).
    
    properties (GetAccess = private, SetAccess = private)
        tasksToDo
        tasksDone
        results
    end
    
    methods (Access = protected)
        % Returns which task will be the next to be run (override me)
        function task = selectNextTask(group)
            if group.completed()
                task = [];
            else
                task = group.tasksToDo(1);
            end
        end
    end
    
    methods
        function [] = addChoice(group, t)
            group.tasksToDo = [group.tasksToDo t];
        end
        
        function value = completed(group)
            value = isempty(group.tasksToDo);
        end
        
        function [success, result] = runOnce(group)
            currentTask = group.selectNextTask();
            
            if isempty(currentTask)
                success = false;
                result = [];
            else
                [success, result] = currentTask.runOnce();
                if currentTask.completed()
                    group.tasksToDo = group.tasksToDo(2:end);
                    group.tasksDone = [group.tasksDone currentTask];
                end
            end
        end
    end
end

