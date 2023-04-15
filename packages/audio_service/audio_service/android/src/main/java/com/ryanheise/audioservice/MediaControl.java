package com.ryanheise.audioservice;

public class MediaControl {
    public final String icon;
    public final String label;
    public final long actionCode;

	public MediaControl(String icon, String label, long actionCode) {
        this.icon = icon;
        this.label = label;
        this.actionCode = actionCode;
	}

    @Override
    public boolean equals(Object other) {
        if (other instanceof MediaControl) {
            MediaControl otherControl = (MediaControl)other;
            return icon.equals(otherControl.icon) && label.equals(otherControl.label) && actionCode == otherControl.actionCode;
        } else {
            return false;
        }
    }
}
