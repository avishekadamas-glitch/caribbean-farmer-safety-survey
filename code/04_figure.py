from pathlib import Path
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
P=Path.cwd()
(P/'figures').mkdir(exist_ok=True)
r=pd.read_csv(P/'results/observed/main_focal.csv')
labels={'Support':'Support and resources','Oversight':'Enforcement and monitoring','Training':'Training recency','Risk':'Risk awareness','Barriers':'Barriers to safety','Benefits':'Perceived safety benefits','Coping':'Coping self efficacy','Confidence':'Safety confidence','Norms':'Descriptive safety norms','PPE':'PPE use','Handling':'Chemical handling','HeatProtection':'Heat protection','Symptoms':'Recent pesticide symptoms'}
titles={'Training':'A  Training recency (0–2)','PPE':'B  PPE use (1–5)','Handling':'C  Chemical handling (1–5)','Symptoms':'D  Recent pesticide symptoms (0–2)','E10':'E  Heat dizziness recurrence (0–2)','Distress':'F  Psychological distress (0–3)'}
plt.rcParams.update({'font.family':'Arial','font.size':12,'axes.titlesize':13,'axes.labelsize':12,'xtick.labelsize':11,'ytick.labelsize':12,'savefig.facecolor':'white'})
fig,axs=plt.subplots(3,2,figsize=(10,10.5),layout='constrained')
for ax,y in zip(axs.flat,titles):
 q=r[r.outcome==y].iloc[::-1]
 pos=list(range(len(q)))
 for i,(_,row) in enumerate(q.iterrows()):
  ax.plot([row.lower,row.upper],[i,i],color='#315c78',lw=1.3)
  ax.plot(row.estimate,i,'o',ms=4.5,mec='#315c78',mfc='#315c78' if row.p_holm<.05 else 'white')
 ax.set_yticks(pos,[labels[x] for x in q.term]);ax.axvline(0,color='#666666',lw=.8,ls='--')
 ax.set_title(titles[y].replace('Recent pesticide symptoms','Recent pesticide\nsymptoms'),loc='left',pad=10);ax.set_xlabel('Adjusted score coefficient')
 ax.set_ylim(-.7,len(q)-.3);ax.spines[['top','right']].set_visible(False);ax.grid(axis='x',color='#ededed',lw=.7);ax.set_axisbelow(True)
fig.savefig(P/'figures/Fig1.png',dpi=300)
fig.savefig(P/'figures/Fig1.tiff',dpi=300,pil_kwargs={'compression':'tiff_lzw'})
from PIL import Image as PILImage
with PILImage.open(P/'figures/Fig1.tiff') as im:
 im.convert('RGB').save(P/'figures/Fig1.tiff',compression='tiff_lzw',dpi=(400,400))
plt.close(fig)
