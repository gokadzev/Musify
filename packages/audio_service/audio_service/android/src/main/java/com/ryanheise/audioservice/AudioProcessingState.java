package com.ryanheise.audioservice;

public enum AudioProcessingState {
    idle,
    loading,
    buffering,
    ready,
    completed,
    error,
}
