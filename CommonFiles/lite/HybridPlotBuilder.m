classdef HybridPlotBuilder < handle

    properties(Constant)
        DEFAULT_PLOT_COLORS = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; 
                               [0.9290 0.6940 0.1250]; [0.4940 0.1840 0.5560]; 
                               [0.4660 0.6740 0.1880]; [0.3010 0.7450 0.9330]; 
                               [0.6350 0.0780 0.1840]];
        DEFAULT_LABELS_TEX = ["x_1", "x_2", "x_3"];
        DEFAULT_LABELS_LATEX = ["$x_1$", "$x_2$", "$x_3$"];
    end

    properties(SetAccess = private)
        titles
        component_labels; 

        % Plot settings
        flow_color = "b";
        flow_line_style string = "-";
        flow_line_width double = 0.5;
        jump_color = "r";
        jump_line_style string = "--";
        jump_line_width double = 0.5;
        jump_start_marker string = ".";
        jump_start_marker_size double = 6;
        jump_end_marker string = "*";
        jump_end_marker_size double = 6;
        text_interpreter = "latex";
    end
    properties(Access = private)
        plots_for_legend = [];
        component_indices uint32 = [];
        timestepsFilter = [];
        max_subplots = 4;
    end

    methods

        function this = title(this, varargin)
            this.titles = varargin;
        end

        function this = labels(this, varargin)
            this.component_labels = varargin;
        end

        function this = flowColor(this, color)
            % FLOWCOLOR Set the color of flow lines.
            this.flow_color = color;
        end

        function this = flowLineStyle(this, style)
            % FLOWLINESTYLE Set the style of flow lines.  If 'style'
            % is an empty string or empty array, then flow lines are hidden. 
            if style == "" || isempty(style)
                this.flow_line_style = "none";
            else
                this.flow_line_style = style;
            end
        end

        function this = flowLineWidth(this, width)
            % FLOWLINEWIDTH Set the width of flow lines.
            assert(width >= 0, "Line width must be positive")
            this.flow_line_width = width;
        end

        function this = jumpColor(this, color)
            % JUMPCOLOR Set the color of jump lines and jump markers.
            % at each end.
            this.jump_color = color;
        end

        function this = jumpLineStyle(this, style)
            % JUMPLINESTYLE Set the style of lines along jumps. If 'style'
            % is an empty string or empty array, then jump lines are hidden. 
            if style == "" || isempty(style)
                this.jump_line_style = "none";
            else
                this.jump_line_style = style;
            end
        end

        function this = jumpLineWidth(this, width)
            % JUMPLINEWIDTH Set the width of jump lines.
            assert(width >= 0, "Line width must be positive")
            this.jump_line_width = width;
        end

        function this = jumpMarker(this, marker)
            % JUMPMARKER Set the marker for both sides of jumps.
            this.jumpStartMarker(marker);
            this.jumpEndMarker(marker);
        end

        function this = jumpMarkerSize(this, size)
            % JUMPMARKERSIZE Set the marker size for both sides of jumps.
            this.jumpStartMarkerSize(size);
            this.jumpEndMarkerSize(size);
        end

        function this = jumpStartMarker(this, marker)
            % JUMPSTARTMARKER Set the marker for the starting point of each
            % jump.
            if marker == "" || isempty(marker)
                this.jump_start_marker = "none";
            else
                this.jump_start_marker = marker;
            end
        end

        function this = jumpStartMarkerSize(this, size)
            % JUMPSTARTMARKERSIZE Set the marker size for the starting 
            % point of each jump.
            assert(size >= 0, "Size must be positive")
            this.jump_start_marker_size = size;
        end

        function this = jumpEndMarker(this, marker)
            % JUMPENDMARKER Set the marker for the end point of each
            % jump.
            if marker == "" || isempty(marker)
                this.jump_end_marker = "none";
            else
                this.jump_end_marker  = marker;
            end
        end

        function this = jumpEndMarkerSize(this, size)
            % JUMPENDMARKERSIZE Set the marker size for the emd 
            % point of each jump.
            assert(size >= 0, "Size must be positive")
            this.jump_end_marker_size = size;
        end

        function this = slice(this, component_indices)
            % SLICE Pick the state components to plot by providing the
            % corresponding indices. 
            this.component_indices = component_indices;
        end

        function this = filter(this, timesteps_filter)
            % FILTER Pick the timesteps to display. All others are hidden
            % from plots. 
            this.timestepsFilter = timesteps_filter;
        end

        function plotflows(this, hybrid_sol)
            indices_to_plot = indicesToPlot(this, hybrid_sol);

            subplot_ndx = 1;
            for i=indices_to_plot
            	open_subplot(length(indices_to_plot), subplot_ndx);
                
                to_plot = [hybrid_sol.t, hybrid_sol.x(:, i)];
                this.plot_sliced(hybrid_sol, to_plot)

                xlabel("$t$", "interpreter", this.text_interpreter)
                this.ylabel(i)
                this.applyTitle(i)
                subplot_ndx = subplot_ndx + 1;
            end 
        end

        function plotjumps(this, hybrid_sol)
            indices_to_plot = indicesToPlot(this, hybrid_sol);

            subplot_ndx = 1;
            for i=indices_to_plot
            	open_subplot(length(indices_to_plot), subplot_ndx);

                sliced_x = [hybrid_sol.j, hybrid_sol.x(:, i)];
                this.plot_sliced(hybrid_sol, sliced_x)

                xlabel("$j$", "interpreter", this.text_interpreter)
                this.ylabel(i)
                this.applyTitle(i)
                subplot_ndx = subplot_ndx + 1;
            end 
        end

        function plotHyrbidArc(this, hybrid_sol)
            indices_to_plot = indicesToPlot(this, hybrid_sol);

            subplot_ndx = 1;
            subplots = [];
            for i=indices_to_plot
            	subplots(subplot_ndx) = open_subplot(length(indices_to_plot), subplot_ndx); %#ok<AGROW>

                % Prepend t and j, then plot.
                sliced_x = [hybrid_sol.t, hybrid_sol.j, hybrid_sol.x(:, i)];
                this.plot_sliced(hybrid_sol, sliced_x)

                xlabel("$t$", "interpreter", this.text_interpreter)
                ylabel("$j$", "interpreter", this.text_interpreter)
                this.zlabel(i)
                this.applyTitle(i)
                subplot_ndx = subplot_ndx + 1;
            end

            % Link the subplot axes so that the views are sync'ed.
            Link = linkprop(subplots,{'CameraUpVector', 'CameraPosition', 'CameraTarget', 'XLim', 'YLim'});
            setappdata(gcf, 'StoreTheLink', Link);
        end

        function plot(this, hybrid_sol)
            % PLOT Plot the hybrid solution in an intelligent way.
            % The output of depends on the dimension of the system 
            % (or the number of components selected with 'slice()'). 
            % The output is as follows: 
            % - 1D: a 1D plot generated using plotflows
            % - 2D: a 2D phase plot
            % - 3D: a 3D phase plot
            % - 4D+: a set of 1D subplots generated using plotflows.
            sliced_indices = indicesToPlot(this, hybrid_sol);
            dimensions = length(sliced_indices);
            
            if dimensions ~= 2 && dimensions ~= 3
                this.plotflows(hybrid_sol)
                return
            end

            sliced_x = hybrid_sol.x(:, sliced_indices);
            this.plot_sliced(hybrid_sol, sliced_x)

            this.xlabel(sliced_indices(1))
            this.ylabel(sliced_indices(2))
            if dimensions == 3
                this.zlabel(sliced_indices(3))
            end
            this.applyTitle(1) % Use first title entry                  
        end

        function lgd = legend(this, varargin)
            % LEGEND Add a legend for each call to builder.plots() while 
            % in the current figure. (Plots in other figures will be
            % skipped).

            % For the current figure, get all the line plots. 
            plots_in_figure = findall(gcf,'Type','Line');
            
            % For each plot saved in this.plots_for_legend, check whether
            % it is a plot in the current figure.
            plots_for_legend_indices ...
                    = ismember(this.plots_for_legend,  plots_in_figure);
            plots_for_this_legend = this.plots_for_legend(plots_for_legend_indices);

            % Print a warning if the number of plots and labels do not
            % match.
            warning_msg = "The number of plots (%d) added to the current figure" + ...
                        " by this HybridPlotBuilder is %s than the number of legend labels provided (%d).";
            labels = varargin;
            if length(plots_for_this_legend) < length(labels)
                warning(warning_msg, length(plots_for_this_legend), "less", length(labels))
            elseif length(plots_for_this_legend) > length(labels)
                warning(warning_msg, length(plots_for_this_legend), "more", length(labels))
            end

            % Add the legend entries for each plot. We truncate the lengths
            % of the arrays to match so that Matlab does not print a
            % (rather unhelpful) warning.
            m = min(length(plots_for_this_legend), length(labels));
            lgd = legend(plots_for_this_legend(1:m), labels(1:m), "interpreter", this.text_interpreter);
        end
    end

    methods(Access = private)

        function plot_sliced(this, hybrid_sol, sliced_x)

            if ~isempty(this.timestepsFilter)
                assert(length(this.timestepsFilter) == size(sliced_x, 1), ...
                    "The length of the filter does not match the timesteps in the HybridSolution.")
                % Set entries that don't match the filter to NaN so they are not plotted.
                sliced_x(~this.timestepsFilter) = NaN;
            end

            % Add an invisible plot that will show up in the legend.
            % Drawing this point will also clear the plot if 'hold' is off
            this.addLegendEntry()
            
            % We have to turn on hold while plotting the hybrid arc, so 
            % we save the current hold state and restore it at the end.
            was_hold_on = ishold();
            hold on

            x_prev = [];
            for j = unique(hybrid_sol.j)'
                interval_of_flow_indices = (hybrid_sol.j == j);
                x_now = sliced_x(interval_of_flow_indices, :);
                switch size(sliced_x, 2)
                    case 2   
                        this.plotFlow2D(x_now)
                        this.plotJump2D(x_prev, x_now)
                    case 3   
                        this.plotFlow3D(x_now)
                        this.plotJump3D(x_prev, x_now)
                        view(34.8,16.8)
                end
                x_prev = x_now;
            end

            % Turn off 'hold' if it was off at the beginning of this
            % function.
            if ~was_hold_on
                hold off
            end
        end
        
        function indices_to_plot = indicesToPlot(this, hybrid_sol)
            n = size(hybrid_sol.x, 2);
            if isempty(this.component_indices)
                last_index = min(n, this.max_subplots); % This 
                indices_to_plot = 1:last_index;
            else
                indices_to_plot = this.component_indices;
            end
            assert(all(indices_to_plot >= 1))
            assert(all(indices_to_plot <= n))
%             if length(component_indices) > 5
%                 warning("Plotting more than five components makes the subplots hard to read")
%             end
        end

        function plotFlow2D(this, x)
            plot(x(:,1), x(:,2), 'Color', this.flow_color, ...
                            'LineStyle', this.flow_line_style, ...
                            'LineWidth', this.flow_line_width)
        end

        function plotFlow3D(this, x)
            plot3(x(:,1), x(:,2), x(:,3), ...
                            'Color', this.flow_color, ...
                            'LineStyle', this.flow_line_style, ...
                            'LineWidth', this.flow_line_width)
        end

        function plotJump2D(this, x_before, x_after)
            if isempty(x_before)
                return % Not a jump
            end
            plot([x_before(end,1); x_after(1,1)], ...
                 [x_before(end,2); x_after(1,2)], ...
                'Color', this.jump_color, ...
                'LineStyle', this.jump_line_style, ...
                'LineWidth', this.jump_line_width)
            % Plot the start of the jump
            plot(x_before(end,1), x_before(end,2), ...
                'Color', this.jump_color, ...
                'Marker', this.jump_start_marker, ...
                'MarkerSize', this.jump_start_marker_size)
            % Plot the end of the jump
            plot(x_after(1,1), x_after(1,2), ...
                'Color', this.jump_color, ...
                'Marker', this.jump_end_marker, ...
                'MarkerSize', this.jump_end_marker_size)
        end

        function plotJump3D(this, x_before, x_after)
            if isempty(x_before)
                return % Not a jump
            end
            plot3([x_before(end,1); x_after(1,1)], ...
                 [x_before(end,2); x_after(1,2)], ...
                 [x_before(end,3); x_after(1,3)], ...
                'Color', this.jump_color, ...
                'LineStyle', this.jump_line_style, ...
                'LineWidth', this.jump_line_width)
            % Plot the start of the jump
            plot3(x_before(end,1), x_before(end,2), x_before(end,3), ...
                'Color', this.jump_color, ...
                'Marker', this.jump_start_marker, ...
                'MarkerSize', this.jump_start_marker_size)
            % Plot the end of the jump
            plot3(x_after(1,1), x_after(1,2), x_after(1,3), ...
                'Color', this.jump_color, ...
                'Marker', this.jump_end_marker, ...
                'MarkerSize', this.jump_end_marker_size)
        end

        function xlabel(this, index)
            if index <= length(this.component_labels)
                xlabel(this.component_labels(index), "interpreter", this.text_interpreter)
            end
        end

        function ylabel(this, index)
            if index <= length(this.component_labels)
                ylabel(this.component_labels(index), "interpreter", this.text_interpreter)
            end
        end

        function zlabel(this, index)
            if index <= length(this.component_labels)
                zlabel(this.component_labels(index), "interpreter", this.text_interpreter)
            end
        end

        function applyTitle(this, index)
            if index <= length(this.titles)
                title(this.titles(index), "interpreter", this.text_interpreter)
            end
        end

        function addLegendEntry(this)
            % We 'plot' a invisible dummy point (NaN values are not visible in plots), 
            % which provides the line and marker appearance for the corresponding legend entry.
            p = plot(nan, nan, "Color", this.flow_color, ...
                                "LineStyle", this.flow_line_style, ...
                                "LineWidth", this.flow_line_width, ...
                                "Marker", this.jump_start_marker, ...
                                "MarkerSize", this.jump_start_marker_size, ...
                                "MarkerEdgeColor", this.jump_color);
            this.plots_for_legend = [this.plots_for_legend, p];
        end
                
    end
end
        
%%% Local functions %%%

function sp = open_subplot(subplots_count, index)
    is_hold_on = ishold(); % Save the hold status to apply in subplots.
    sp = subplot(subplots_count, 1, index);
    if is_hold_on
        % Subplots default to hold off, so we modify the hold
        % status to match what was met before 
        hold on
    end
end