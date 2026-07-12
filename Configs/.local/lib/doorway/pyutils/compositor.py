import os
import json
import socket as _socket
from typing import Union, Any


class HyprctlWrapper:
    @staticmethod
    def _socket_path() -> str:
        his = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
        if not his:
            raise EnvironmentError(
                "HYPRLAND_INSTANCE_SIGNATURE is not set. Is Hyprland running?"
            )
        runtime_dir = os.getenv("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        return os.path.join(runtime_dir, "hypr", his, ".socket.sock")

    @staticmethod
    def _send(command: str) -> str:
        """Send a command to the Hyprland IPC socket and return the response.

        Format: [flags]/command args  (e.g. 'j/getoption decoration:rounding')
        The socket is opened immediately before the request and closed right after,
        as required by Hyprland's synchronous socket model.
        """
        with _socket.socket(_socket.AF_UNIX, _socket.SOCK_STREAM) as sock:
            sock.connect(HyprctlWrapper._socket_path())
            sock.sendall(command.encode())
            sock.shutdown(_socket.SHUT_WR)
            chunks = []
            while chunk := sock.recv(4096):
                chunks.append(chunk)
        return b"".join(chunks).decode()

    @staticmethod
    def getoption(option: str, get_set: bool = False) -> Union[int, str, bool, Any]:
        """
        Get a Hyprland option value via the IPC socket.

        Args:
            option: Option name (e.g., 'decoration:rounding')
            get_set: If True, returns the 'set' value instead of the actual value

        Returns:
            The option value or set status depending on get_set parameter
        """
        output = HyprctlWrapper._send(f"j/getoption {option}")

        try:
            data = json.loads(output)
            if get_set:
                return data.get("set", False)

            # Try to get the value in order of preference
            for key in ["int", "float", "str", "bool"]:
                if key in data:
                    return data[key]

            return None

        except json.JSONDecodeError:
            raise ValueError(f"Failed to parse hyprctl output: {output}")

    @staticmethod
    def is_hovered() -> bool:
        """
        Check if the cursor is hovered on a window.

        Returns:
            True if the cursor is hovered on a window, False otherwise.
        """
        cursor_pos = json.loads(HyprctlWrapper._send("j/cursorpos"))
        active_window = json.loads(HyprctlWrapper._send("j/activewindow"))

        cursor_x = cursor_pos.get("x", 0)
        cursor_y = cursor_pos.get("y", 0)
        window_x = active_window.get("at", [0, 0])[0]
        window_y = active_window.get("at", [0, 0])[1]
        window_size_x = active_window.get("size", [0, 0])[0]
        window_size_y = active_window.get("size", [0, 0])[1]

        if (
            window_x <= cursor_x <= window_x + window_size_x
            and window_y <= cursor_y <= window_y + window_size_y
        ):
            return True
        return False
