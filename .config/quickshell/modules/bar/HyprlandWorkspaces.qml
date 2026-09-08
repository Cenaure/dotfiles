import QtQuick
import Quickshell.Hyprland

import qs.components
import qs.configurations

Item {
		id: root

		implicitWidth: row.implicitWidth + BarConfig.workspacesTrackPadding * 2
		implicitHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2

		// Build a stable list of workspace "slots": always show 1..visibleWorkspaces,
		// plus any additional real workspace beyond that range (e.g. workspace 12
		// opened manually) so nothing active ever gets hidden.
		readonly property var slotIds: {
				const ids = [];
				for (let i = 1; i <= BarConfig.visibleWorkspaces; i++)
						ids.push(i);

				for (const ws of Hyprland.workspaces.values) {
						if (ws.id > 0 && !ids.includes(ws.id))
								ids.push(ws.id);
				}

				return ids.sort((a, b) => a - b);
		}

		// Geometry of the capsule, published by whichever slot currently holds focus
		// (see the Bindings in the delegate). Resolving the slot from up here with
		// Repeater.itemAt() does not work: itemAt() is a plain function that never
		// re-evaluates, and rebuilding slotIds recreates every delegate without
		// changing count, so the cached Item silently goes stale.
		property real highlightX: 0
		property real highlightWidth: 0

		// Window class for a toplevel. A window opened after the shell started
		// arrives over the event socket with an empty lastIpcObject, so its
		// .class is undefined there, while wayland.appId is populated; windows
		// present at startup carry both. Preferring appId keeps the icon correct
		// in both cases, with lastIpcObject.class kept as the fallback.
		function classOf(toplevel) {
			if (!toplevel)
				return "";

			return toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "";
		}

		function workspaceFor(id) {
				for (const ws of Hyprland.workspaces.values) {
						if (ws.id === id)
								return ws;
				}
				return null;
		}

		// All workspace switching goes through here, including slots backed by a
		// real workspace. HyprlandWorkspace.activate() is deliberately not used:
		// under a Lua Hyprland config the plain "workspace N" dispatch form is a
		// Lua syntax error, and this keeps both paths on one verified form.
		// JSON.stringify yields the right Lua literal for either argument shape:
		// a bare 5 for an id, or a quoted "e+1" for a relative move.
		function focusWorkspace(target) {
				if (BarConfig.hyprlandLuaConfig)
						Hyprland.dispatch(`hl.dsp.focus({ workspace = ${JSON.stringify(target)} })`);
				else
						Hyprland.dispatch(`workspace ${target}`);
		}

		function switchRelative(delta) {
				const step = BarConfig.scrollExistingOnly
						? (delta > 0 ? "e+1" : "e-1")
						: (delta > 0 ? "+1" : "-1");
				root.focusWorkspace(step);
		}

		// Track first, highlight above it, row on top: the capsule slides behind
		// the slot content rather than covering it.
		Rectangle {
				id: track
				anchors.fill: parent
				radius: height / 2
				color: BarConfig.workspacesTrackColor
				opacity: BarConfig.workspacesTrackOpacity
		}

		Rectangle {
				id: highlight

				visible: root.highlightWidth > 0
				x: root.highlightX
				width: root.highlightWidth
				height: BarConfig.workspaceHeight
				anchors.verticalCenter: parent.verticalCenter
				radius: height / 2
				color: BarConfig.workspaceActiveColor

				Behavior on x {
						NumberAnimation {
								duration: BarConfig.workspacesAnimationDuration
								easing.type: Easing.OutCubic
						}
				}

				Behavior on width {
						NumberAnimation {
								duration: BarConfig.workspacesAnimationDuration
								easing.type: Easing.OutCubic
						}
				}
		}

		Row {
				id: row

				x: BarConfig.workspacesTrackPadding
				anchors.verticalCenter: parent.verticalCenter
				spacing: BarConfig.workspacesSpacing

				Repeater {
						id: repeater

						model: root.slotIds

						delegate: Item {
								id: slot

								required property int modelData

								readonly property var workspace: root.workspaceFor(slot.modelData)
								readonly property var windows: slot.workspace?.toplevels?.values ?? []
								readonly property bool isActive: slot.workspace?.focused ?? false
								readonly property bool isOccupied: slot.windows.length > 0
								readonly property bool isUrgent: slot.workspace?.urgent ?? false

								readonly property int shownCount: Math.min(slot.windows.length, BarConfig.workspaceMaxIcons)
								readonly property int overflowCount: slot.windows.length - slot.shownCount

								readonly property color contentColor: slot.isActive
										? BarConfig.workspaceActiveForeground
										: slot.isUrgent
												? BarConfig.workspaceUrgentColor
												: slot.isOccupied
														? BarConfig.workspaceColor
														: BarConfig.workspaceEmptyColor

								height: BarConfig.workspaceHeight
								width: Math.max(BarConfig.workspaceWidth,
																content.implicitWidth + BarConfig.workspacePadding * 2)

								Behavior on width {
										NumberAnimation {
												duration: BarConfig.workspacesAnimationDuration
												easing.type: Easing.OutCubic
										}
								}

								// Push this slot's geometry up while it holds focus. Driving it
								// from the delegate keeps the capsule correct across delegate
								// rebuilds and as slots resize when windows open and close.
								Binding {
										target: root
										property: "highlightX"
										value: row.x + slot.x
										when: slot.isActive
										restoreMode: Binding.RestoreNone
								}

								Binding {
										target: root
										property: "highlightWidth"
										value: slot.width
										when: slot.isActive
										restoreMode: Binding.RestoreNone
								}

								Row {
										id: content

										anchors.centerIn: parent
										spacing: BarConfig.workspaceIconSpacing

										// Children all take the slot height and centre their own
										// text, so the Row needs no per-child vertical anchoring.

										// An empty workspace keeps its number, so the row stays
										// readable and never reflows as windows come and go.
										Text {
												visible: !slot.isOccupied && BarConfig.showId
												text: slot.modelData
												color: slot.contentColor
												height: BarConfig.workspaceHeight
												verticalAlignment: Text.AlignVCenter
												font.family: "AnnotationM Nerd Font"
												font.pixelSize: 12
												font.weight: Font.DemiBold

												Behavior on color {
														ColorAnimation { duration: BarConfig.workspacesAnimationDuration }
												}
										}

										Repeater {
												model: slot.shownCount

												delegate: AppIcon {
														required property int index

														windowClass: root.classOf(slot.windows[index])
														color: slot.contentColor
														height: BarConfig.workspaceHeight

														Behavior on color {
																ColorAnimation { duration: BarConfig.workspacesAnimationDuration }
														}
												}
										}

										Text {
												visible: slot.overflowCount > 0
												text: "+" + slot.overflowCount
												color: slot.contentColor
												height: BarConfig.workspaceHeight
												verticalAlignment: Text.AlignVCenter
												font.family: "AnnotationM Nerd Font"
												font.pixelSize: 10
												font.weight: Font.DemiBold

												Behavior on color {
														ColorAnimation { duration: BarConfig.workspacesAnimationDuration }
												}
										}
								}

								MouseArea {
										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										acceptedButtons: Qt.LeftButton

										// Dispatching by id covers both cases: a slot for a
										// workspace that has never been visited has no
										// HyprlandWorkspace object to activate() in the first place.
										onClicked: root.focusWorkspace(slot.modelData)

										onWheel: (event) => {
												root.switchRelative(event.angleDelta.y > 0 ? -1 : 1);
												event.accepted = true;
										}
								}
						}
				}
		}
}
