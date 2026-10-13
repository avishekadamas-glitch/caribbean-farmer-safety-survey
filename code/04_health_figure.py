from pathlib import Path
import argparse
import json
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import NullLocator, NullFormatter
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
ap.add_argument('--coefficients')
ap.add_argument('--out')
args = ap.parse_args()
root = args.root.resolve()
coefficients = Path(args.coefficients) if args.coefficients else root/'results/primary_family/health_primary_focal.csv'
out = Path(args.out) if args.out else root/'figures'
out.mkdir(parents=True, exist_ok=True)
d = pd.read_csv(coefficients)
assert len(d) == 8 and d.analysis_id.nunique() == 8 and d.family_size.eq(26).all()
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 8.5, 'axes.titlesize': 9.2,
                     'axes.labelsize': 8.5, 'xtick.labelsize': 8, 'ytick.labelsize': 8.5,
                     'savefig.facecolor': 'white', 'pdf.fonttype': 42, 'svg.fonttype': 'none'})
color = '#315C78'
labels = {'PPE': 'PPE use', 'Handling': 'Chemical handling', 'HeatProtection': 'Heat protection',
          'Coping': 'Coping summary', 'Confidence': 'Safety confidence summary',
          'Symptoms': 'Recent pesticide symptoms'}
panels = [
    ('Symptoms', ['PPE','Handling'], [.30,.745,.34,.17], 'A  Recent pesticide symptom recurrence', 'Mean recurrence-score difference (b)'),
    ('HeatOccurrence', ['HeatProtection'], [.30,.495,.34,.12], 'B  Any heat-related dizziness', 'Odds ratio (log scale)'),
    ('Distress', ['PPE','Handling','Coping','Confidence','Symptoms'], [.30,.145,.34,.25], 'C  Farm-related distress', 'Mean distress-score difference (b)')
]
fig = plt.figure(figsize=(7.5,7.6))
fig.text(.69,.972,'Estimate [nominal 95% CI]',fontsize=8.1)
fig.text(.976,.972,'Holm p',fontsize=8.1,ha='right')
plotted = []
def number(x):
    return f'{x:.3f}'.replace('-', '−')
for outcome, terms, position, title, xlabel in panels:
    dd = d[d.outcome.eq(outcome)].set_index('predictor').loc[terms].reset_index()
    assert dd.n.nunique() == 1
    ax = fig.add_axes(position)
    ys = np.arange(len(dd))[::-1]
    ax.set_ylim(-.6,len(dd)-.4)
    ax.set_yticks(ys,[labels[t] for t in terms])
    ax.tick_params(axis='y',length=0,pad=8)
    ax.grid(axis='x',color='#E5E5E5',lw=.6)
    ax.set_axisbelow(True)
    ax.spines[['top','right','left']].set_visible(False)
    ax.spines['bottom'].set_color('#555555')
    if outcome == 'HeatOccurrence':
        ax.set_xscale('log');ax.set_xlim(.45,1.15)
        ax.set_xticks([.5,.65,.8,1.]);ax.set_xticklabels(['0.50','0.65','0.80','1.00'])
        ax.xaxis.set_minor_locator(NullLocator());ax.xaxis.set_minor_formatter(NullFormatter())
        ax.axvline(1,color='#555555',lw=.8,ls='--')
        value, lower, upper = 'odds_ratio','or_lower','or_upper'
    else:
        ax.axvline(0,color='#555555',lw=.8,ls='--')
        value, lower, upper = 'estimate','ci_lower','ci_upper'
        if outcome == 'Symptoms':
            ax.set_xlim(-.16,.055);ax.set_xticks([-.15,-.10,-.05,0]);ax.set_xticklabels(['−0.15','−0.10','−0.05','0'])
        else:
            ax.set_xlim(-.20,.65);ax.set_xticks([-.2,0,.2,.4,.6]);ax.set_xticklabels(['−0.2','0','0.2','0.4','0.6'])
    ax.set_xlabel(xlabel,labelpad=5)
    ax.set_title(f'{title} (n = {int(dd.n.iloc[0]):,})',loc='left',pad=15)
    for y, (_, row) in zip(ys, dd.iterrows()):
        lo, est, hi = float(row[lower]),float(row[value]),float(row[upper])
        assert lo <= est <= hi
        ax.plot([lo,hi],[y,y],color=color,lw=1.2,zorder=2)
        significant = row.p_holm < .05
        ax.plot(est,y,marker='o',ms=5.2,markerfacecolor=color if significant else 'white',markeredgecolor=color,
                markeredgewidth=1.1,linestyle='none',zorder=3)
        fy = position[1]+position[3]*(y+.6)/(len(dd)+.2)
        fig.text(.69,fy,f'{number(est)} [{number(lo)}, {number(hi)}]',va='center',fontsize=8.2)
        ptext = '<0.001' if row.p_holm < .001 else f'{row.p_holm:.3f}'
        fig.text(.976,fy,ptext,ha='right',va='center',fontsize=8.2)
        plotted.append(dict(analysis_id=row.analysis_id,outcome=outcome,predictor=row.predictor,n=int(row.n),
                            plotted_estimate=est,plotted_lower=lo,plotted_upper=hi,
                            scale='odds ratio, logarithmic axis' if outcome=='HeatOccurrence' else 'unstandardized score coefficient',
                            p_holm=float(row.p_holm),family_size=26,filled_marker=bool(significant)))
fig.text(.035,.052,'Intervals are nominal 95% robust intervals; Holm correction covers 26 primary focal tests.',fontsize=8.2)
legend = fig.add_axes([.035,.012,.93,.027]);legend.axis('off')
legend.plot(.010,.5,'o',ms=5.2,mfc=color,mec=color,transform=legend.transAxes)
legend.text(.030,.5,'Holm p < 0.05',va='center',fontsize=8.2,transform=legend.transAxes)
legend.plot(.260,.5,'o',ms=5.2,mfc='white',mec=color,transform=legend.transAxes)
legend.text(.280,.5,'Holm p ≥ 0.05',va='center',fontsize=8.2,transform=legend.transAxes)
legend.text(.550,.5,'Associations do not establish causal protection.',va='center',fontsize=8.2,transform=legend.transAxes)
fig.savefig(out/'Fig2.png',dpi=400,facecolor='white')
fig.savefig(out/'Fig2.tiff',dpi=400,facecolor='white',pil_kwargs={'compression':'tiff_lzw'})
with Image.open(out/'Fig2.tiff') as im:
    im.convert('RGB').save(out/'Fig2.tiff',compression='tiff_lzw',dpi=(400,400))
pd.DataFrame(plotted).to_csv(out/'Fig2_plot_data.csv',index=False)
checks=[]
for fn in ['Fig2.png','Fig2.tiff']:
    with Image.open(out/fn) as im:
        checks.append(dict(file=fn,pixels=list(im.size),mode=im.mode,dpi=[float(v) for v in im.info.get('dpi',())],
                           compression=im.info.get('compression'),bytes=(out/fn).stat().st_size))
(out/'Fig2_technical_checks.json').write_text(json.dumps(checks,indent=2))
plt.close(fig)
print(json.dumps(checks,indent=2))
