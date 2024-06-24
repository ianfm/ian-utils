# ~/.collect_history.sh
# requires the following in .bashrc
# trap /home/$USER/.collect_history.sh EXIT
history -a
echo "session history recorded"
sleep 1