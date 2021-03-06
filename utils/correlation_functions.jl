module Correlation_Functions
export form_atomic_time_series, autocorrelation_function, custom_acf, plot_correlation_function, vdos, plot_vdos
using FFTW, DSP, Plots, LaTeXStrings, ProgressBars

    function form_atomic_time_series(frames::AbstractArray)
        return transpose(hcat(vec.(frames)...))
    end

    function autocorrelation_function(time_series::AbstractArray, block_width::Int, num_lags_per_window::Int=20, max_blocks::Int=0)
        """
        Compute the autocorrelation function of a single time series or many time series computed
        as a matrix of time series where each column is a time series. This will average the acf over
        as many disconnected blocks of length block_width as possible, unless the optional max_blocks is specified.
        """
        signal = zeros(block_width)
        num_blocks = convert(Int, floor(size(time_series, 1) / block_width))
        if max_blocks > 0 && max_blocks < num_blocks
            num_blocks = max_blocks
        end
        block_stride = convert(Int, floor(block_width / 20))

        for col in ProgressBar(eachcol(time_series))
            for i_block in 1:num_blocks
                for i_slide in 1:block_width:block_stride
                    block = @inbounds @view col[(i_block-1)*block_width+1+(i_slide-1):i_block*block_width+(i_slide-1)]
                    signal += DSP.xcorr(block, block)[block_width:end]
                end
                signal /= num_lags_per_window
            end
            signal /= num_blocks
        end
        return signal / signal[begin]
    end

    function plot_correlation_function(time_series::AbstractArray, frame_spacing::Float64)
        plotlyjs()
        display(plot((1:length(time_series)) * frame_spacing, time_series, 
        label="ACF Signal", 
        xlims=(0, 2500), 
        xlabel="Time (fs)", 
        ylabel="Signal Correlation"))
    end

    function vdos(signal::AbstractArray, frame_spacing::Float64)
        """
        Computes the vibrational density of states from the velocity autocorrelation function.
        Args:
            signal: 1-D array representing some time series
            frame_spacing: float which is the spacing in femtoseconds of the frames
        Return: both the fourier frequencies and the signal intensity as a tuple. 
        """
        freqs = FFTW.rfftfreq(length(signal), 1 / frame_spacing)[1:floor(Int64, length(signal)/2)] * 10^(15) / (2.9979*(10^10)) # fs to cm^-1
        vdos = real.(FFTW.rfft(signal)[1:floor(Int64, length(signal)/2)])
        return freqs, vdos
    end

    function plot_vdos(frequencies::AbstractArray, vdos::AbstractArray)
        plotlyjs()
        plot(frequencies, vdos, 
        label="VDOS", 
        xlims=(1000, 4400), 
        ylims=(0, 15),
        xlabel=(L"Frequency (cm^{-1})"),
        ylabel=("Intensity"))
    end

end