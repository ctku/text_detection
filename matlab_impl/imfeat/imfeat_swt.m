function [param] = imfeat_swt(cmd1, cmd2, param)

switch cmd1
    case 'initialization'
        param.rd.mode = 'gray';
    case 'extract_feature_mask'
        param.feat_mask = imfeat_swt_algo(param.image);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SWTImage = imfeat_swt_algo(Image)

im = Image;
edgeImage = edge(im,'canny');
% figure,imshow(edgeImage);

[dx dy] = gradient(double(im));

prec = 0.05;
dark_on_light = 0;
[row_image col_image] = size(im);
flag = 0;
cnt=1;
SWTImage = zeros(row_image,col_image)-1;
for row = 1:row_image
    for col = 1:col_image
        
        if( edgeImage( row, col) < 1 )
            continue;
        end
        
        p.x = col;
        p.y = row;
        r.p = p;
        k = 1;
        clear points;
        points(k) = p;
        
        curX = col + 0.5;
        curY = row + 0.5;
        curPixX = col;
        curPixY = row;
        
        G_x = dx(row,col);
        G_y = dy(row,col);
        %         if (G_x~=0&&G_y~=0)
        mag = sqrt((G_x * G_x) + (G_y * G_y));
        
        if(dark_on_light)
            G_x = -G_x/mag;
            G_y = -G_y/mag;
        else
            G_x = G_x/mag;
            G_y = G_y/mag;
        end
        
        while(flag==0)
            curX = curX + G_x * prec;
            curY = curY + G_y * prec;
            
            if ( (uint16(curX) ~= uint16(curPixX)) || (uint16(curY) ~= uint16(curPixY)) )
                curPixX = double(uint16(curX));
                curPixY = double(uint16(curY));
  
                if (curPixX <=0||curPixX>col_image||curPixY <=0 ||curPixY >row_image)
                    break
                end
                pnew.x = curPixX;
                pnew.y = curPixY;
                k = k + 1;
                points(k) = pnew;
                if (edgeImage(curPixY,curPixX)>0)
                    r.q = pnew;
                    G_xt = dx(curPixY,curPixX);
                    G_yt = dy(curPixY,curPixX);
                    
                    mag = sqrt(G_xt*G_xt + G_yt*G_yt);
                    if(dark_on_light)
                        G_xt = -G_xt/mag;
                        G_yt = -G_yt/mag;
                    else
                        G_xt = G_xt/mag;
                        G_yt = G_yt/mag;
                    end
                    if(acos(G_x * -G_xt + G_y * -G_yt) < pi/2)
                        len = sqrt(double((r.q.x - r.p.x)*(r.q.x - r.p.x) + (r.q.y - r.p.y)*(r.q.y - r.p.y)));
                        
                        for m=1:k
                            if (SWTImage(points(m).y,points(m).x)<0)
                                SWTImage(points(m).y,points(m).x) = len;
                            else
                                SWTImage(points(m).y,points(m).x) = min(len,SWTImage(points(m).y,points(m).x));
                            end
                        end
                        
                        r.points = points;
                        rays(cnt)=r; cnt=cnt+1;
                    end
                    break
                end
            end
        end
    end
end
% end
% figure,imagesc(SWTImage); colorbar;
if exist('rays')
    for i=1:length(rays)-1          %each rays
        cnt1 = 1;
        for j=1:length(rays(i).points)  %each points on the rays
            xxx(cnt1) = SWTImage(rays(i).points(j).y,rays(i).points(j).x);

            cnt1 = cnt1+1;
        end
        rays(i).med = median(xxx);

        for j=1:length(rays(i).points)  %each points on the rays
            SWTImage(rays(i).points(j).y,rays(i).points(j).x)= min(SWTImage(rays(i).points(j).y,rays(i).points(j).x),rays(i).med);
        end    
    end
end
% SWTImage(SWTImage == -1) = max( SWTImage(:) );
% figure,imagesc(SWTImage); colorbar;

end