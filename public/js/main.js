import React, { useState, useEffect } from 'react';

function Alarm() {
    const [alarm, setAlarm] = useState({
        time: '00:00',
        enabled: false,
    });
    const [status, setStatus] = useState('');

    useEffect(() => {
        // Get the initial alarm data
        getAlarmData();
    }, []);

    function getAlarmData() {
        // Send GET request to server to get alarm data
        fetch('/alarm')
            .then(response => response.json())
            .then(data => {
                // Update the alarm data in the component
                setAlarm({
                    time: `${data.hour}:${data.minute}`,
                    enabled: data.enabled,
                });
            })
            .catch(error => console.error(error));
    }

    function saveAlarmData() {
        // Send PUT request to server to save alarm data
        fetch('/alarm', {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                hour: Number(alarm.time.split(':')[0]),
                minute: Number(alarm.time.split(':')[1]),
                zone: -(new Date()).getTimezoneOffset() * 60,
                enabled: alarm.enabled,
            }),
        })
            .then(response => {
                if (response.ok) {
                    // Update the status message in the component
                    setStatus('Saved');
                } else {
                    setStatus('Unknown error! Please try again.');
                }
            })
            .catch(error => console.error(error));
    }

    return (
        <div>
            <input
                type="time"
                value={alarm.time}
                onChange={event =>
                    setAlarm({ ...alarm, time: event.target.value })
                }
            />
            <label>
                <input
                    type="checkbox"
                    checked={alarm.enabled}
                    onChange={event =>
                        setAlarm({ ...alarm, enabled: event.target.checked })
                    }
                />
                Enabled
            </label>
            {status && <p className="status">{status}</p>}
            <button onClick={saveAlarmData}>Save</button>
        </div>
    );
}

export default Alarm;