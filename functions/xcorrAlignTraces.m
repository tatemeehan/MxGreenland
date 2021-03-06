function [ Rad, xcorrShift ] = xcorrAlignTraces( Rad, grab)
% xcorrAlign aligns traces across adjacent files where time zero may have
% drifted.
%   The mean of the final N and initial N traces of adjacent files are
%   cross correlated and the maximum correlation lag is used to adjust the
%   radar gram.
%
%       Inputs: Rad - Cell Array nChanXnFiles Contains the According Data
%               grab - Vector of Samples to compute xCorr and MER Picking
%                  N - Number of Traces to Average before xCorr
%
%       Output: Rad - Time Shifted Radargram
%
%       Written by: Tate Meehan, Boise State University, GreenTrACS 2017

nFiles = size(Rad,2);
nChan = size(Rad,1);
chan = 1:nChan;
xcorrShift = cell(nChan,nFiles);

if size(grab,1) == 1
    grab = [ones(1,nChan);grab];
end

for ii = 1:nFiles -1
    for jj = chan
        % Create Template Trace for xCorr - AirWave only in Window
        trc1 = AGCgain(mean(Rad{jj,ii}(grab(1,jj):grab(2,jj),1:end),2),50,1);
        trc2 = AGCgain(mean(Rad{jj,ii+1}(grab(1,jj):grab(2,jj),1:end),2),50,1);
%         % Pad Joints with Average of Edge Traces
%         % Do this To Eliminte Effects of FxDecon Filter & Array Turning
%         meanTrc = mean([Rad{jj,ii}(:,end-50:end),Rad{jj,ii+1}(:,1:51)],2);
%         Rad{jj,ii}(:,end-50:end) = meanTrc*ones(1,51); % Stack Traces on End of File
%         Rad{jj,ii+1}(:,1:51) = meanTrc*ones(1,51);   % Stack Traces on Start of File
        % Compute Cross Correlation of File Template Trace
        [val, lag] = xcorr(trc1,trc2);
        [~, lagIx] = max(val);
        align = lag(lagIx);
        % Apply Circular Shifts
        switch (sign(align))
            case -1
                strip = Rad{jj,ii+1}(1:abs(align),:);
                Rad{jj,ii+1}(1:abs(align),:) = [];
                Rad{jj,ii+1} = [Rad{jj,ii+1};strip];
                clear strip
            case 1
                dup = repmat(Rad{jj,ii+1}(1,:),align,1);
                Rad{jj,ii+1}(size(Rad{jj,ii+1},1)-(align-1):end,:) = [];
                Rad{jj,ii+1} = [dup;Rad{jj,ii+1}];
                clear dup
            case 0 
        end
        if ii == 1
            xcorrShift{jj,ii} = 0;
            xcorrShift{jj,ii+1} = align;
        else
            xcorrShift{jj,ii+1} = align;
        end
    end
end
end

