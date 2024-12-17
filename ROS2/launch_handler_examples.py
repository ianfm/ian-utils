# Launch expressions and snippets

import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription, launch_description_sources, LaunchContext, EventHandler
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument, ExecuteProcess, TimerAction, OpaqueFunction, IncludeLaunchDescription, SetEnvironmentVariable, RegisterEventHandler, EmitEvent, LogInfo
from launch.substitutions import LaunchConfiguration, PythonExpression, TextSubstitution, LocalSubstitution, EnvironmentVariable
from launch.conditions import IfCondition
from launch.event_handlers import OnExecutionComplete, OnProcessExit, OnProcessIO, OnProcessStart, OnShutdown
from launch.events import Shutdown
import launch
import logging

# Establishing a local LaunchContext is one way to enable evaluating LaunchConfiguration variables
local_context = LaunchContext()

# Launch configuration
override_tf = LaunchConfiguration('override_tf', default=True)


def generate_launch_description():
    
    ld = LaunchDescription()
    
    # Example process 1
    p1 = ExecuteProcess(
        name='p1',
        condition=IfCondition(
            PythonExpression([
                override_tf
            ])
        ),
        cmd=[[
            'echo ',
            '\'Using PythonExpression() '
            'I found override_tf: ',
            override_tf,
            '\''
        ]],
        shell=True
    )
    
    # Example process 2
    p2 = ExecuteProcess(
        name='p2',
        condition=IfCondition(
            override_tf.perform(local_context)
        ),
        cmd=[[
            'echo ',
            '\'Using x.perform(local_context)'
            'I found override_tf: ',
            override_tf,
            '\''        ]],
        shell=True,
        
    )
    
    # dunno why the lamdas
    def on_err_output(event: launch.events.process.ProcessIO):
        lambda event: LogInfo(
                msg='Ignore sterr pls')
    def on_std_output(event: launch.events.process.ProcessIO):
        lambda event: LogInfo(
                msg='Spawn request says "{}"'.format(
                        event.text.decode().strip()))
    
    
    # Event handlers allow control over the behavior of a process or node
    handle_io = RegisterEventHandler(
        OnProcessIO(
            # target_action=p1,
            on_stdout=on_std_output,
            on_stderr=on_err_output
        )
    )

    handle_exit = RegisterEventHandler(
        OnProcessExit(
            # target_action=p1,
            on_exit=[
                LogInfo(msg='Finder completed'),
                EmitEvent(event=Shutdown(
                    reason='Window closed'))
            ],
        )
    )

    handle_shutdown = RegisterEventHandler(
        OnShutdown(
            on_shutdown=[LogInfo(
                # msg='hi there     8888'
                msg=['Launch was asked to shutdown: ',
                    LocalSubstitution('event.reason')]
            )]
        )
    )
    
    # Glorious
    logging.disable()
    
    ld.add_action(handle_exit)
    ld.add_action(handle_shutdown)
    ld.add_action(handle_io)
    ld.add_action(p1)
    ld.add_action(p2)

    return ld
