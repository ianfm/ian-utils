%% CAN bus transmission time

bitrate = 250e3
msgframes = 3
framelen = 64 % bits
format shortg
t_frame = framelen / bitrate
t_msg = msgframes * t_frame

% sending a 3 frame message over the wire would take around 1 ms

