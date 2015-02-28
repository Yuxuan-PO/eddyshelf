function [slope, pbot, angmom] = syms_angmom(runs)

    syms r z
    syms Lr Lz theta positive
    syms f H positive
    syms ra negative
    syms vb

    bta0 = runs.params.phys.beta;
    g = runs.params.phys.g;
    r0 = runs.params.phys.rho0;

    if isempty(runs.usurf), runs.read_velsurf; end
    % fit gaussian to surface velocity
    tic;
    for tt=1:length(runs.eddy.cy)
        ix = find_approx(runs.rgrid.x_rho(1,:), runs.eddy.mx(tt));
        uvec = double(runs.usurf(ix,:,tt)');
        zvec = double(runs.zeta(ix,2:end-1,tt)'.*runs.eddy.mask(ix,:,tt)');
        yuvec = runs.rgrid.y_u(:,ix) - runs.eddy.my(tt);
        yzvec = runs.rgrid.y_rho(2:end-1,ix) - runs.eddy.my(tt);

        %hold off; plot(yvec, uvec);
        %ylim([-1 1]* 0.2); xlim([-3 3]*1e5);
        %linex(0); liney(0);
        %pause(0.1);
        [V0(tt), Lfit(tt)] = exp_fit(yuvec, uvec,0);
        [z0(tt), Lfitz(tt)] = gauss_fit(yzvec, zvec-min(zvec(:)), 1);
    end
    toc;

    ra0 = -r0 * runs.params.phys.TCOEF * runs.eddy.T(:,end)';
    Lr0 = Lfit; %runs.eddy.vor.dia/2;
    Lz0 = runs.eddy.Lgauss;
    H0 = runs.eddy.hcen';
    f0 = runs.eddy.fcen';
    vb0 = runs.eddy.Vb;

    alpha = runs.bathy.sl_slope;

    %    bta0 = 1; ra0 = -1; Lr0 = 1; Lz0 = 1; H0 = Inf; vb0 = 0; f0 = ...
    %       1; g = 1; r0 = 1;

    % profile shapes
    R(r,Lr) = exp(-(r/Lr)^2);
    F(z,Lz) = exp(-(z/Lz)^2);

    rho(ra, r,Lr,z,Lz) = ra .* R(r,Lr) .* F(z,Lz);

    % geostrophic azimuthal velocity shear
    uz = g/r0/f * diff(rho,r);
    ugeo(ra,r,Lr,z,Lz,f,H) = int(uz, z, -H, z);

    usurf = double(ugeo(ra0,Lr0,Lr0,0,Lz0,f0,H0));

    vbr(vb,r,Lr) = vb * diff(R,r);
    %zeta(r,Lr,Lz,f,vb,ra,H) =  (f/g * vb * R(r,Lr) - 1/r0 * int(rho,z,-H,0));

    amgeo(Lr,Lz,f,ra,H) = bta0 * integrate_r(r*sin(theta)*ugeo*-sin(theta));
    ambot(vb,Lr) = bta0 * int(int(r*sin(theta)*vbr*-sin(theta), r, ...
                                  -Inf, Inf), theta, 0, 2*pi);

    % for some reason, it doesn't do the cancellation in pbc+pbt correctly.
    %pbc(ra,Lr,Lz,H) = integrate_r(g/r0 * rho);
    %pbt = int(g*zeta, r, -Inf, Inf);
    %pbotr(ra,r,Lr,Lz,H) = g*(zeta + 1/r0 * int(rho, z,-H, 0));

    % geostrophically balanced bottom pressure
    pbottom(f,vb,Lr) = 2*pi*int(f * vb *Lr * R, r, -Inf, Inf);

    %pbot = double(pbc(ra0, Lr0, Lz0, H0) + ...
    %              pbt(Lr0, Lz0, f0, vb0, ra0, H0));

    pbot = double(pbottom(f0,vb0,Lr0));
    angmom = double(amgeo(Lr0,Lz0,f0,ra0,H0) + ambot(vb0,Lr0));
    slope = angmom./pbot;

    plots = 0;
    if plots
        [~,~,tind] = runs.locate_resistance;
        figure;
        plot(2*pi*slope); linex([tind runs.traj.tind]);
        liney(alpha); title(runs.name);
    end

end

function [out] = integrate_r(in)

    syms r z
    syms theta Lr Lx Ly Lz positive
    syms ra f
    syms H

    out = int(int(int(in,r,-Inf,Inf),theta,0,2*pi),z,-H,0);
end

% I want to fit y = y_0 tanh(x/X)
function [y0, X] = exp_fit(x, y, plot_flag, test)

    if ~exist('test', 'var'), test = 0; end
    if ~exist('plot_flag', 'var'), plot_flag = 0; end

    if test
        test_fit();
        return;
    end

    initGuess(1) = max(y(:));
    initGuess(2) = max(x(:))/2;

    opts = optimset('MaxFunEvals',1e7);
    [fit2,~,exitflag] = fminsearch(@(fit) fiterror(fit,x,y), ...
                                   initGuess,opts);

    y0 = fit2(1);
    X = fit2(2);

    if plot_flag
        figure;
        plot(x,y,'k*'); hold all
        plot(x, y0*(2*x/X) .* exp( -(x/X).^2));
        liney([-1 1]* y0);
        linex([-1 1]*X);
    end
end

function [E] = fiterror(fit,x,y)
% x = (T0,H,a)
    y0 = fit(1); X = fit(2);

    E = sum((y - y0 .* (2*x/X) .* exp(-(x/X).^2)).^2);
end

function [] = test_fit()
    x = [-4:0.05:4];
    X = 1;
    y0 = 1;
    y = y0 * (2*x/X) .* exp(-(x/X).^2);

    [yy,xx] = exp_fit(x,y,1);

    disp(['y0 = ' num2str(yy) ' | Original = ' num2str(y0)]);
    disp(['X = ' num2str(xx) ' | Original = ' num2str(X)]);
end
