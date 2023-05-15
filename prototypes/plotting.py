#! /usr/bin/env nix-shell
#! nix-shell <nixpkgs> -i python3 -p "python39.withPackages(x: with x; [ pandas matplotlib scipy seaborn])"

import pandas as pd
from matplotlib import pyplot as plt
import matplotlib.dates as md
import os
import seaborn as sns
from datetime import timedelta, datetime
import numpy as np
from scipy import stats
from itertools import combinations


class Plotting():
    def __init__(self, base_dir, xlabel, ylabel, fig_base_dir, label_transform=None, modify_y_label=True, start_from_zero=False, no_title=False):
        self.base_dir = base_dir
        self.xlabel = xlabel
        self.ylabel = ylabel
        self.fig_base_dir = fig_base_dir
        self.label_transform = label_transform
        self.start_from_zero = start_from_zero
        self.data = []
        self.no_title = no_title
        if modify_y_label:
            self.ylabel += " [s]"

    def set_figure_path(self, title):
        self.figure_path = os.path.join(
            self.fig_base_dir, title.lower().replace(" ", "_"))

    def set_start_from_zero(self, cond):
        self.start_from_zero = cond

    def set_label_transform(self, label_transform):
        self.label_transform = label_transform

    def annotate_brackets(self, num1, num2, data, center, height, dh=.05, barh=.05, fs=None, maxasterix=3):
        """
        Annotate barplot with p-values.

        :param num1: number of left bar to put bracket over
        :param num2: number of right bar to put bracket over
        :param data: string to write or number for generating asterixes
        :param center: centers of all bars (like plt.bar() input)
        :param height: heights of all bars (like plt.bar() input)
        :param dh: height offset over bar / bar + yerr in axes coordinates (0 to 1)
        :param barh: bar height in axes coordinates (0 to 1)
        :param fs: font size
        """

        if type(data) is str:
            text = data
        else:
            # * is p < 0.05
            # ** is p < 0.005
            # *** is p < 0.0005
            # etc.
            text = ''
            p = .05

            while data < p:
                text += '*'
                p /= 10.

                if maxasterix and len(text) == maxasterix:
                    break

            if len(text) == 0:
                text = 'n. s.'
        lx, ly = center[num1], height[num1]
        rx, ry = center[num2], height[num2]

        ax_y0, ax_y1 = plt.gca().get_ylim()
        dh *= (ax_y1 - ax_y0)
        barh *= (ax_y1 - ax_y0)

        y = max(ly, ry) + dh

        barx = [lx, lx, rx, rx]
        bary = [y, y+barh, y+barh, y]
        mid = ((lx+rx)/2, y+barh)

        kwargs = dict(ha='center', va='bottom', c='black')
        linecolor = 'black'
        if fs is not None:
            kwargs['fontsize'] = fs
        plt.text(*mid, text, **kwargs)
        plt.plot(barx, bary, c=linecolor, linewidth=1)

    def plot_benchmarks(self, title, xlabel=None, data=None, get_ylim=False, ylim_top=None):
        '''
        data = [{ label: "", x:[], y: [] }]
        '''
        if data != None:
            self.data = data
        if xlabel != None:
            self.xlabel = xlabel

        self.set_figure_path(title.replace(".", ""))
        x_pos = np.arange(len(self.data))
        ymeans = []
        data_df = pd.DataFrame()
        for data_pt in self.data:
            times = []
            for t in data_pt['y']:
                s = t.split(":")
                hours, i = 0, 0
                if len(s) == 3:
                    hours = float(s[0])
                    i = 1
                time = timedelta(hours=hours, minutes=float(
                    s[0+i]), seconds=float(s[1+i])).total_seconds()
                times.append(time)
            ymeans.append(np.mean(times))
            data_df[data_pt['label']] = times

        fig, ax = plt.subplots()
        sns.set_theme(style="whitegrid")
        ax = sns.boxplot(data=data_df, showmeans=True, meanprops={
            'marker': '*', 'markerfacecolor': 'white', 'markeredgecolor': 'black'})
        # ax.bar(x_pos, ymeans, yerr=error, align='center', alpha=0.5, ecolor='black', capsize=10, color=color)

        two_pair_combin = list(combinations(range(data_df.shape[1]), 2))
        for (i, j) in two_pair_combin:
            # * Statistical tests for differences in the features across groups
            times_i = data_df.iloc[:, i]
            times_j = data_df.iloc[:, j]
            var1, var2 = np.var(times_i), np.var(times_j)
            # Rule of thumb: variance is similar if ratio is smaller than two
            # https://en.wikipedia.org/wiki/Student%27s_t-test#Independent_two-sample_t-test
            equal_var = True if max(var1, var2) / \
                min(var1, var2) < 2 else False
            t, p = stats.ttest_ind(times_i, times_j, equal_var=equal_var)
            self.annotate_brackets(i, j, p, x_pos, ymeans)

        ax.grid(alpha=0.5, axis='y')
        ax.set_xticks(x_pos)
        ax.set_ylabel(self.ylabel)
        ax.set_xlabel(self.xlabel)

        if self.start_from_zero:
            ax.set_ylim((0, None))
        if ylim_top is not None:
            ax.set_ylim((None, ylim_top))
        y_lim = ax.get_ylim()
        # ax.set_xticklabels(labels, wrap=True, rotation = 45, ha="right")
        # ax.set_xticklabels(labels)
        if not self.no_title:
            ax.set_title(title, loc='center', wrap=True, pad=15)
        plt.tight_layout()
        plt.savefig(self.figure_path)
        plt.clf()
        plt.cla()
        plt.close()
        if get_ylim:
            return y_lim

    def data_from_files(self, files, ycolumn='real', ycolumn_2=None, xcolumn='index'):
        data = []
        for file in files:
            path = os.path.join(self.base_dir, file)
            df = pd.read_csv(path, engine='python',
                             skiprows=1, skipfooter=1)
            df.reset_index(inplace=True)
            label = self.label_transform(
                file) if self.label_transform != None else file
            dp = {"x": df[xcolumn],
                  'y': df[ycolumn], 'label': label}
            if ycolumn_2 != None:
                dp['y2'] = df[ycolumn_2]
            data.append(dp)
        self.data = data
        return self.data

    def plot_benchmarks_with_two_axis(self, title, yvalue_transform=id, ylabel_2=None):
        self.set_figure_path(title)
        assert(len(self.data) > 0)
        for data_pt in self.data:
            x = data_pt['x']
            # file_name = data_pt['file']
            yvalues_1 = [yvalue_transform(t) for t in data_pt['y']]
            yvalues_2 = [yvalue_transform(t) for t in data_pt['y2']]

            fig, ax1 = plt.subplots()
            ax1.set_ylabel(self.ylabel, color='black')
            ax1.set_xlabel(self.xlabel, color='black')
            ax1.plot(x, yvalues_1, "o-", color='black')
            ax1.tick_params(axis='y', labelcolor='black')
            ax1.grid(False)

            ax2 = ax1.twinx()
            ax2.set_ylabel(ylabel_2, color='green')
            ax2.plot(x, yvalues_2, "o-",  color='green')
            ax2.tick_params(axis='y', labelcolor='green')
            ax2.grid(False)

        plt.title(title)
        fig.tight_layout()
        plt.savefig(self.figure_path)
        plt.clf()
        plt.cla()
        plt.close()


def plot_nix_shell_at_runtime():
    xlabel = "runtime execution strategy"
    ylabel = "real time"
    base_dir = "nix-shell-at-runtime/benchmarks"
    fig_base_dir = "nix-shell-at-runtime/plots"
    def label_transform(l): return " ".join(l.split("_")[2:-2])
    plotting = Plotting(base_dir, xlabel, ylabel,
                        fig_base_dir, label_transform=label_transform)

    files = [
        "cpp_bench_cached_shell_empty_store.csv",
        "cpp_bench_uncached_shell_empty_store.csv"
    ]
    plotting.data_from_files(files)
    title = "Cached versus uncached nix-shell with empty Nix store: C++"
    plotting.plot_benchmarks(title)

    files = [
        "python_bench_cached_shell_empty_store.csv",
        "python_bench_uncached_shell_empty_store.csv"
    ]
    title = "Cached versus uncached nix-shell with empty Nix store: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "cpp_bench_cached_shell_full_store.csv",
        "cpp_bench_uncached_shell_full_store.csv"
    ]
    plotting.data_from_files(files)
    title = "Cached versus uncached nix-shell with full Nix store: C++"
    plotting.plot_benchmarks(title)

    files = [
        "python_bench_cached_shell_full_store.csv",
        "python_bench_uncached_shell_full_store.csv"
    ]
    title = "Cached versus uncached nix-shell with full Nix store: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "cpp_bench_cached_shell_with_seeded_store.csv",
        "cpp_bench_cached_shell_empty_store.csv"
    ]
    def label_transform(l): return " ".join(l.split("_")[-2:])[:-4]
    plotting.set_start_from_zero(True)
    plotting.set_label_transform(label_transform=label_transform)
    plotting.data_from_files(files)
    title = "Seeded versus empty Nix store with cached shell: C++"
    xlabel = "Nix store setup"
    plotting.plot_benchmarks(title, xlabel=xlabel)

    files = [
        "python_bench_cached_shell_with_seeded_store.csv",
        "python_bench_cached_shell_empty_store.csv"
    ]
    title = "Seeded versus empty Nix store with cached shell: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "cpp_bench_cached_shell_with_seeded_store.csv",
        "cpp_bench_cached_shell_full_store.csv"
    ]

    plotting.data_from_files(files)
    title = "Seeded versus full Nix store with cached shell: C++"
    plotting.plot_benchmarks(title)

    files = [
        "python_bench_cached_shell_with_seeded_store.csv",
        "python_bench_cached_shell_full_store.csv"
    ]
    title = "Seeded versus full Nix store with cached shell: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)


def plot_build_at_runtime():
    xlabel = "build and push strategy"
    ylabel = "real time"
    base_dir = "build-image-at-runtime/benchmarks"
    fig_base_dir = "build-image-at-runtime/plots"
    def label_transform(l): return " ".join(l.split("_")[-2:-1])
    plotting = Plotting(base_dir, xlabel, ylabel,
                        fig_base_dir, label_transform=label_transform)

    files = [
        "cpp_bench_empty_build_cache_layered_local.csv",
        "cpp_bench_empty_build_cache_streamed_local.csv"
    ]
    title = "Build layered versus streamed and push to local registry with empty Nix store: C++"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "python_bench_empty_build_cache_layered_local.csv",
        "python_bench_empty_build_cache_streamed_local.csv"
    ]
    title = "Build layered versus streamed and push to local registry with empty Nix store: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "cpp_bench_full_build_cache_layered_local.csv",
        "cpp_bench_full_build_cache_streamed_local.csv"
    ]
    title = "Build layered versus streamed and push to local registry with full Nix store: C++"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "python_bench_full_build_cache_layered_local.csv",
        "python_bench_full_build_cache_streamed_local.csv"
    ]
    title = "Build layered versus streamed and push to local registry with full Nix store: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    def label_transform(l): return " ".join(l.split("_")[2:-2])
    plotting.set_label_transform(label_transform)
    fig_size = (6.4, 8)
    plotting.set_start_from_zero(True)
    files = [
        "cpp_bench_pull_create_start_streamed_local.csv",
        "cpp_bench_startup_streamed_local.csv"
    ]
    title = "Pull from registry and startup container versus local container startup: C++"
    xlabel = "container start strategy"
    data = plotting.data_from_files(files)
    plotting.plot_benchmarks(title, xlabel=xlabel)

    files = [
        "python_bench_pull_create_start_streamed_local.csv",
        "python_bench_startup_streamed_local.csv"
    ]
    title = "Pull from registry and startup container versus local container startup: Python"
    plotting.data_from_files(files)
    plotting.plot_benchmarks(title)

    files = [
        "python_growing_image_stats_streamed_local.csv"
    ]
    def yvalue_transform(v): return int(
        v[:-2]) if str(v)[-2:] == 'MB' else int(v)

    ylabel = 'Image size [MB]'
    ylabel_2 = 'No. layers'
    xlabel = "number of packages in python environment"
    title = "Image statistics with growing python enivonments"
    plotting = Plotting(base_dir, xlabel, ylabel,
                        fig_base_dir, modify_y_label=False)
    plotting.data_from_files(files, ycolumn='Image_size',
                             ycolumn_2='#layers', xcolumn='Config')
    plotting.plot_benchmarks_with_two_axis(
        title, yvalue_transform=yvalue_transform, ylabel_2=ylabel_2)


def plot_BAR_vs_NSAR():
    xlabel = "approach"
    ylabel = "real time"
    base_dir_a1 = "nix-shell-at-runtime/benchmarks"
    base_dir_a2 = "build-image-at-runtime/benchmarks"
    fig_base_dir = "plot-compare-approaches"
    def label_transform_1(x): return "NSAR"
    def label_transform_2(x): return "BIAR"
    plotting1 = Plotting(base_dir_a1, xlabel, ylabel,
                         fig_base_dir, label_transform=label_transform_1, start_from_zero=True)
    plotting2 = Plotting(base_dir_a2, xlabel, ylabel,
                         fig_base_dir, label_transform=label_transform_2, start_from_zero=True)
    files_a2 = [
        "cpp_bench_startup_streamed_local.csv"
    ]

    files_a1 = [
        "cpp_bench_cached_shell_full_store.csv"
    ]
    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    title = "Compare BIAR with NSAR on subsequent-time build performance: C++"
    data = data_a1 + data_a2
    plotting2.plot_benchmarks(title, data=data)

    files_a2 = [
        "python_bench_startup_streamed_local.csv"
    ]
    files_a1 = [
        "python_bench_cached_shell_full_store.csv"
    ]
    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    title = "Compare BIAR with NSAR on subsequent-time build performance: Python"
    data = data_a1 + data_a2
    plotting2.plot_benchmarks(title, data=data)
    # TODO: include pull and startup in comparison
    files_a2 = [
        "cpp_bench_empty_build_cache_streamed_local.csv"
    ]

    files_a1 = [
        "cpp_bench_cached_shell_empty_store.csv"
    ]

    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    title = 'Compare BIAR with NSAR on first-time build performance: C++'
    data = data_a1 + data_a2
    plotting2.plot_benchmarks(title, data=data)

    files_a2 = [
        "python_bench_empty_build_cache_streamed_local.csv"
    ]
    files_a1 = [
        "python_bench_cached_shell_empty_store.csv"
    ]

    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    title = 'Compare BIAR with NSAR on first-time build performance: Python'
    data = data_a1 + data_a2
    plotting2.plot_benchmarks(title, data=data)


def plot_BAR_vs_NSAR_vs_cxenv():
    xlabel = ""
    ylabel = "real time"
    base_dir_a1 = "nix-shell-at-runtime/benchmarks"
    base_dir_a2 = "build-image-at-runtime/benchmarks"
    base_dir_cxenv = "cxenv_benchmarks"
    fig_base_dir = "plot-compare-approaches"
    def label_transform_1(x): return "NSAR"
    def label_transform_2(x): return "BIAR"
    def label_transform_cxenv(x): return "Current Approach"
    plotting1 = Plotting(base_dir_a1, xlabel, ylabel,
                         fig_base_dir, label_transform=label_transform_1, start_from_zero=True)
    plotting2 = Plotting(base_dir_a2, xlabel, ylabel,
                         fig_base_dir, label_transform=label_transform_2,  start_from_zero=True)
    plotting3 = Plotting(base_dir_cxenv, xlabel, ylabel,
                         fig_base_dir, label_transform=label_transform_cxenv,  start_from_zero=True, no_title=False)

    files_a2 = [
        "cpp_bench_startup_streamed_local.csv",
    ]
    files_a1 = [
        "cpp_bench_cached_shell_full_store.csv",
    ]
    files_cxenv = [
        "gcc-8_bench_startup.csv",
    ]
    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    data_cxenv = plotting3.data_from_files(files_cxenv)
    data = data_a1 + data_a2 + data_cxenv
    title = "Compare prototypes with current approach on subsequent-time performance: C++"
    plotting3.plot_benchmarks(title, data=data)

    files_a2 = [
        "python_bench_startup_streamed_local.csv",
    ]
    files_a1 = [
        "python_bench_cached_shell_full_store.csv",
    ]
    files_cxenv = [
        "python-3_8_bench_startup.csv"
    ]
    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    data_cxenv = plotting3.data_from_files(files_cxenv)
    title = "Compare prototypes with current approach on subsequent-time performance: Python"
    plotting3.plot_benchmarks(title, data=data)

    files_a2 = [
        "python_bench_empty_build_cache_streamed_startup.csv",
    ]
    files_a1 = [
        "python_bench_cached_shell_empty_store.csv",
    ]
    files_cxenv = [
        "python-3_8_bench_build_startup.csv"
    ]
    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    data_cxenv = plotting3.data_from_files(files_cxenv)
    data = data_a1 + data_a2 + data_cxenv
    title = 'Compare prototypes with current approach on first-time build performance: Python'
    _, ylim_top = plotting3.plot_benchmarks(title, data=data, get_ylim=True)

    files_a2 = [
        "cpp_bench_empty_build_cache_streamed_startup.csv",
    ]
    files_a1 = [
        "cpp_bench_cached_shell_empty_store.csv",
    ]
    files_cxenv = [
        "gcc-8_bench_build_startup.csv",
    ]
    data_a1 = plotting1.data_from_files(files_a1)
    data_a2 = plotting2.data_from_files(files_a2)
    data_cxenv = plotting3.data_from_files(files_cxenv)
    data = data_a1 + data_a2 + data_cxenv
    title = 'Compare prototypes with current approach on first-time build performance: C++'
    plotting3.plot_benchmarks(title, data=data, ylim_top=ylim_top)


plot_nix_shell_at_runtime()
plot_build_at_runtime()
plot_BAR_vs_NSAR()
plot_BAR_vs_NSAR_vs_cxenv()
