cam = webcam; %Create webcam object
fig = uifigure;
btn = uibutton(fig, 'push',...
    'Text', 'Close Stream',...
    'ButtonPushedFcn', @(i) closefig(i));


res = str2double(split(string(cam.Resolution),'x')); %Get camera resolution
n = 25; %Grid size
threshhold = 0.1; %Don't display optical flow below threshhold
[p,x,y] = generatesubimageindex(res,n);

frame0 = getfft(getframe(cam,res,n)); %Initialize first frame
maxcross = @(k,m) maxcrosscorr(k,m,n);

i = true;
while i
    image = getframe(cam,res,n); %Get new frame grid
    imshow(cell2mat(image)) %Display video
    hold on
    frame = getfft(image); %fourier transform of intensity of image
    
    [u,v] = cellfun(@(n,m) maxcross(n,m),frame0,frame,'UniformOutput',false);
    quiver(x,y,cell2mat(u)',cell2mat(v)')
    hold off
    frame0 = frame; %Cycle frames
end

delete(cam)
close all

function i = closefig(i)
    i = false;
end

function [u,v] = maxcrosscorr(U,T,n)
    UT = U.*conj(T);
    prod = ifft2(UT./abs(UT)); %Calculates the cross power then transfroms it to the cross correlation
    [M,I] = max(prod);
    [~,J] = max(M);
    v = I(J);
    %There's a coordinate transformation issue here going from the corner
    %of a subimage to the center.
    u = J;
end

function [mindex,xx,yy] = generatesubimageindex(res,n)
    remzero = @(n) n(n~=0);

    k = @(j) ceil(res(j)./n); %Number of subimages in the j direction
    l = @(j) remzero([ones(1,floor(res(j)/n))*n,rem(res(j),n)]); %Number of pixels per subimage in the j direction
    m = @(n) cumsum(l(n))-(l(n))/2; %Number of pixels per subimage in the n direction as a matrix
    
    [xx,yy] = ndgrid(m(1),m(2));
    [ii,jj] = ndgrid(1:k(2),1:k(1));
    mindex = mat2cell(cat(3,ii,jj),ones(1,k(2)),ones(1,k(1)),2); %(subimage_x, subimage_y, subimagepix_x, subimagepix_y)
end

function frame = getframe(cam,res,n)
    k = @(j) [ones(1,floor(res(j)/n))*n,rem(res(j),n)]; %Calculate number of pixels per subimage
    frame = mat2cell(snapshot(cam),k(2),k(1),3); %Divide image matrix into cell array of subimage matricies
end

function fftframe = getfft(image)
    fftframe = cellfun(@(n)fft2(filter2(ones(3,3),rgb2gray(n),'same')),image,'UniformOutput',false);
    %Here I used a blur kernel for removing noise -without this the program
    %starts tracking noise. I should use a lowpass filter after
    %applying fft2 though, since applying the blur filter is computationaly
    %expensive.
end