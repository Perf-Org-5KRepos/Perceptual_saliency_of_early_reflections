% [r, id, isAudible] = reduceReflections(r, N, method, fs, doPlot, show_plot)
% redues a list of refelctions to a fixed number N
%
% I N P U T:
% r      - list of refelctions in the format generated by
%          detectRefelctions.m
% N      - Number of refelctions to keep
% method - 'loudest'
%          'first'
%          'exceed'
% fs     - sampling frequency in Hz
% doPlot - false to omitt plots, true or string that specifies the plot
%          title to do the plots
%
%
% O U T P U T:
% r         - reduced list of refelctions in the same format as the input
%             with N+1 entries (N reflections + first sound)
% id        - vector with N+1 entries giving the indicees of the
%             reflections selected from the input parameter r (see above)
% isAudible - logical vector indicating which samples of the underlying
%             spatial room impulse response are belong to the list of
%             reflections
%
%
% fabian.brinkmann@tu-berlin.de, Audio Communication Group TU Berlin &
% Microsoft Research, Redmond, USA

%   Copyright 2019 Microsoft Corporation
%   
%   Permission is hereby granted, free of charge, to any person obtaining a 
%   copy of this software and associated documentation files (the "Software"), 
%   to deal in the Software without restriction, including without limitation 
%   the rights to use, copy, modify, merge, publish, distribute, sublicense, 
%   and/or sell copies of the Software, and to permit persons to whom the 
%   Software is furnished to do so, subject to the following conditions:
%   
%   The above copyright notice and this permission notice shall be included in 
%   all copies or substantial portions of the Software.
%   
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
%   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
%   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
%   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
%   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
%   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
%   DEALINGS IN THE SOFTWARE.
function [r, id, isAudible] = reduceReflections(r, N, method, fs, doPlot, show_plot)

% ------------------------------------------------------------- check input
if numel(r.t) <= 1
    return
end

if ischar(doPlot)
    plotTitle = doPlot;
    doPlot    = true;
end
if ~exist('plotTitle', 'var')
    plotTitle = '';
end

N = min(N, numel(r.t)-1);

rFull = r;


% ----------------------------------- get the N most important refelctions
% delta_t = r.t(2:end) - r.t(1);

switch lower(method)
    case 'loudest'
        [~, id] = sort(r.a(2:end), 'descend');
    case 'first'
        id = (1:N)';
    case 'exceed'
        [~, id] = sort(r.L_mask(2:end), 'descend');
    otherwise
        error('reduceReflections:method', 'Unknown method.')
end

% include first sound
id = [1; id(1:N)+1];


% -------------------------------------- discard less important reflections

f = fields(r);

for nn = 1:numel(f)
    r.(f{nn}) = r.(f{nn})(id,:);
end

% allocate space for audibility indication
isAudible = false(2*2e5,1);
M         = 0;

% compile vector of audible contributions
for nn = 1:N+1
    M = max(max(r.id{nn}, M));
    isAudible(r.id{nn}) = true;
end

isAudible = isAudible(1:M+1);


% -------------------------------------------------------------------- plot
if doPlot
    
    rir            = zeros(rFull.n(end)+1, 1);
    rir(rFull.n)   = rFull.a / max(abs(rFull.a));
    doa            = zeros(rFull.n(end)+1, 3);
    doa(:,1)       = 1;
    doa(rFull.n,:) = rFull.xyz;
    
    nID = rFull.n(id);
    
    ph = newFig(12,18, show_plot);
    ph.Name = 'SRIR';
    
    tMax = max(rFull.t);
    tMax = tMax - rem(tMax,10e-3) + 10e-3;
    tMax = tMax * 1e3;
    
    yMin = min(db( rFull.a/max(rFull.a) ));
    yMin = yMin - rem(yMin, 5) - 5;
    
    [~, mID] = max(abs(rir));

    subplot(3,1,1)
        RIR      = rir;
        RIR(nID) = 0;
        RIR(mID) = rir(mID); % copy the maximum to keep the scale
        plotSRIR(RIR, doa, 'rir', fs, r.t(1)+.1, abs(yMin), false, 'scatter', {'.' 1 10}, 'B')
        RIR      = (yMin-1)*ones(size(RIR));
        RIR(nID) = db(r.a/max(r.a));
        hold on
        plot((0:numel(RIR)-1)/fs*1e3, RIR, 'color', [.71 .071 .094], 'LineWidth', 1)
        title(['EDC (' plotTitle ')'])
        xlim([0 tMax])
    subplot(3,1,2)
        RIR      = rir;
        RIR(nID) = 0;
        RIR(mID) = rir(mID)*.95; % copy the maximum to keep the scale and scale to make sure that it is not plotted above the actual maximum
        plotSRIR(RIR, doa, 'lat', fs, r.t(1)+.1, abs(yMin), false, 'scatter', {'.' 1 10}, 'B')
        RIR      = zeros(size(RIR));
        RIR(nID) = r.a/max(r.a);
        plotSRIR(RIR, doa, 'lat', fs, r.t(1)+.1, abs(yMin), false, 'scatter', {'.' 1 10}, 'R', false)
        title(['Lateral angle (' plotTitle ')'])
        xlim([0 tMax])
    subplot(3,1,3)
        RIR      = rir/max(abs(rir));
        RIR(nID) = 0;
        RIR(mID) = rir(mID)/max(abs(rir))*.95; % copy the maximum to keep the scale and scale to make sure that it is not plotted above the actual maximum
        plotSRIR(RIR, doa, 'pol', fs, r.t(1)+.1, abs(yMin), false, 'scatter', {'.' 1 10}, 'B')
        RIR      = zeros(size(RIR));
        RIR(nID) = r.a/max(r.a);
        plotSRIR(RIR, doa, 'pol', fs, r.t(1)+.1, abs(yMin), false, 'scatter', {'.' 1 10}, 'R', false)
        title(['Polar angle (' plotTitle ')'])
        xlim([0 tMax])

end